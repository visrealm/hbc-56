/*
 * Troy's HBC-56 Emulator - Debugger
 *
 * Copyright (c) 2021 Troy Schrapel
 *
 * This code is licensed under the MIT license
 *
 * https://github.com/visrealm/hbc-56/emulator
 *
 */

#define _CRT_SECURE_NO_WARNINGS


#include "debugger.h"
#include "../devices/tms9918_device.h"
#include "vrEmuTms9918Util.h"
#include "vrEmu6502.h"
#include "imgui.h"

#include <stdlib.h>
#include <ctype.h>
#include <string.h>
#include <string>
#include <bitset>
#include <vector>
#include <map>
#include <set>
#include <memory>


extern "C" uint8_t hbc56MemRead(uint16_t addr, bool dbg);

uint16_t debugMemoryAddr = 0;
uint16_t debugTmsMemoryAddr = 0;

static VrEmu6502 *cpu6502 = NULL;

static char *labelMap[0x10000] = {NULL};
static HBC56Device* tms9918 = NULL;

static char tmpBuffer[256] = {0};

static std::map<std::string, int> constants;

static uint16_t highlightAddr = 0;

static std::set<char> operators = {'!','^','-','/','%','+','<','>','=','&','|','(',')'};

static int isProbablyConstant(const char* str)
{
  SDL_strlcpy(tmpBuffer, str, sizeof(tmpBuffer) - 1);
  SDL_strupr(tmpBuffer);
  return SDL_strcmp(str, tmpBuffer) == 0;
}

void debuggerLoadLabels(const char* labelFileContents)
{
  for (int i = 0; i < sizeof(labelMap) / sizeof(const char*); ++i)
  {
    if (labelMap[i])
    {
      free(labelMap[i]);
      labelMap[i] = NULL;
    }
  }

  if (labelFileContents)
  {
    char lineBuffer[1024];

    char *p = (char*)labelFileContents;

    for (;;)
    {
      char* end = SDL_strchr(p, '\n');
      if (end == NULL)
        break;

      SDL_strlcpy(lineBuffer, p, end - p);
      p = end + 1;

      size_t labelStart = (size_t )-1, labelEnd = (size_t)-1, valueStart = (size_t)-1, valueEnd = (size_t)-1;

      int i = 0;
      int len = strlen(lineBuffer);
      for (i = 0; i < len; ++i)
      {
        char c = lineBuffer[i];
        if (c == 0) break;
        if (!isspace(c) && c != '=' && c != '$')
        {
          if (labelStart == -1)
          {
            labelStart = i;
          }
          else if (labelEnd != -1 && valueStart == -1)
          {
            valueStart = i;
          }
        }
        else
        {
          if (labelStart != -1 && labelEnd == -1)
          {
            labelEnd = i;
          }
          else if (valueStart != -1 && valueEnd == -1)
          {
            valueEnd = i;
          }
        }
      }

      if (valueStart == -1)
      {
        continue;
      }
      else if (valueEnd == -1)
      {
        valueEnd = i;
      }


      char valueStr[100] = { 0 };

      SDL_strlcpy(valueStr, lineBuffer + valueStart, valueEnd - valueStart + 1);

      unsigned int value = 0;
      SDL_sscanf(valueStr, "%x", &value);

      uint16_t addr = (uint16_t)value;

      bool isUnused = SDL_strstr(lineBuffer, "; unused") != NULL;

      constants[std::string(lineBuffer + labelStart, labelEnd - labelStart)] = addr;

      if (!labelMap[addr] || (isProbablyConstant(labelMap[addr]) && !isUnused))
      {
        char* label = (char*)malloc((labelEnd - labelStart) + 1);
        SDL_strlcpy(label, lineBuffer + labelStart, labelEnd - labelStart + 1);
        labelMap[addr] = label;
      }
    }
  }
}

std::map<std::string, std::vector<std::string> > source;
std::map<int, std::pair<std::string, int> > addrMap;
std::set<std::string> opcodes;



class Token
{
public:
  typedef std::shared_ptr<Token> Ptr;

  typedef enum Type
  {
    LINE,
    WHITESPACE,
    COMMENT,
    OPCODE,
    COMMA,
    NUMBER,
    STRING,
    OPERATOR,
    IMMEDIATE,
    MACRO,
    CONSTANT,
    LABEL,
    UNKNOWN
  };

  static Ptr Create(Token::Type type, const std::string& value)
  {
    return Ptr(new Token(type, value));
  }

  Token::Type type() const { return m_type; }
  const std::string &value() const { return m_value; }
  const std::vector<Token::Ptr> &children() const { return m_children; }

  void addChild(Token::Ptr child) { m_children.push_back(child); }

private:
  Token(Token::Type type, const std::string& value)
    : m_type(type), m_value(value)
  {

  }

  Token::Type             m_type;
  std::string             m_value;
  std::vector<Token::Ptr> m_children;

};

void parseLine(const std::string& line, size_t from, Token::Ptr parent)
{
  for (int i = from; i < line.size(); ++i)
  {
    if (line[i] == ';')
    {
      parent->addChild(Token::Create(Token::COMMENT, line));
      return;
    }
    else if (line[i] == '\'')
    {
      size_t start = i;
      ++i;
      for (; i < line.size(); ++i)
      {
        if (line[i] == '\'' && line[i - 1] != '\\') break;
      }
      parent->addChild(Token::Create(Token::STRING, line.substr(start, i - start)));
      --i;
    }
    else if (line[i] == '"')
    {
      size_t start = i;
      ++i;
      for (; i < line.size(); ++i)
      {
        if (line[i] == '"' && line[i - 1] != '\\') break;
      }
      parent->addChild(Token::Create(Token::STRING, line.substr(start, i - start)));
      --i;
    }
    else if (isspace(line[i]))
    {
      size_t start = i;
      for (; i < line.size(); ++i)
      {
        if (!isspace(line[i])) break;
      }
      parent->addChild(Token::Create(Token::WHITESPACE, line.substr(start, i - start)));
      --i;
    }
    else if (line[i] == ',')
    {
      parent->addChild(Token::Create(Token::COMMA, line.substr(i, 1)));
    }
    else if (line[i] == '#')
    {
      parent->addChild(Token::Create(Token::IMMEDIATE, line.substr(i, 1)));
    }
    else if (line[i] == '+' && (parent->children().empty() || parent->children()[0]->type() == Token::WHITESPACE))
    {
      size_t start = i++;
      for (; i < line.size(); ++i)
      {
        if (!isalnum(line[i]) && line[i] != '_' && line[i] <= 127) break;
      }
      parent->addChild(Token::Create(Token::MACRO, line.substr(start, i - start)));
      --i;
    }
    else if (line[i] == '.' || line[i] == '@' || isalpha(line[i]))
    {
      size_t start = i++;
      for (; i < line.size(); ++i)
      {
        if (!isalnum(line[i]) && line[i] != '_' && line[i] <= 127) break;
      }

      Token::Type type = start == 0 ? Token::LABEL : Token::CONSTANT;
      std::string word = line.substr(start, i - start);

      if (isalpha(line[start]))
      {
        if (opcodes.find(word) != opcodes.end())
        {
          type = Token::OPCODE;
        }
        else if (word == "DIV")
        {
          type = Token::OPERATOR;
        }
      }

      parent->addChild(Token::Create(type, word));
      --i;
    }
    else if (line[i] == '$' || (line[i] == '0' && line[i+1] == 'x')) // hex
    {
      size_t start = i++;
      for (; i < line.size(); ++i)
      {
        if (!isxdigit(line[i])) break;
      }
      parent->addChild(Token::Create(Token::NUMBER, line.substr(start, i - start)));
      --i;
    }
    else if (line[i] == '%' && (line[i+1] == '0' || line[i + 1] == '1' || line[i + 1] == '#' || line[i + 1] == '.')) // binary
    {
      size_t start = i++;
      for (; i < line.size(); ++i)
      {
        if (line[i] != '0' && line[i] != '1' && line[i] != '.' && line[i] != '#') break;
      }
      parent->addChild(Token::Create(Token::NUMBER, line.substr(start, i - start)));
      --i;
    }
    else if (line[i] == '&' && isdigit(line[i+1])) // octal
    {
      size_t start = i++;
      for (; i < line.size(); ++i)
      {
        if (line[i] < '0' || line[i]  > '7') break;
      }
      parent->addChild(Token::Create(Token::NUMBER, line.substr(start, i - start)));
      --i;
    }
    else if (isdigit(line[i]))
    {
      size_t start = i;
      for (; i < line.size(); ++i)
      {
        if (!isdigit(line[i]) && line[i] != '.') break;
      }
      parent->addChild(Token::Create(Token::NUMBER, line.substr(start, i - start)));
      --i;
    }
    else
    {
      size_t start = i;
      if (operators.find(line[i]) != operators.end())
      {
        for (; i < line.size(); ++i)
        {
          if (operators.find(line[i]) == operators.end()) break;
        }
        parent->addChild(Token::Create(Token::OPERATOR, line.substr(start, i - start)));
        --i;
      }
      else
      {
        parent->addChild(Token::Create(Token::UNKNOWN, line.substr(i, 1)));
      }
    }
  }

}



void debuggerLoadSource(const char* rptFileContents)
{
  for (int i = 0; i < 256; ++i)
  {
    opcodes.insert(vrEmu6502OpcodeToMnemonicStr(cpu6502, i & 0xff));
  }

  if (rptFileContents)
  {

    char* p = (char*)rptFileContents;
    std::string filename = "";

    for (;;)
    {
      char* end = SDL_strchr(p, '\n');
      if (end == NULL)
        break;

      if (end == p) {++p; continue;}


      std::string line(p, end - p);
      p += end - p;
      if (line.size() < 2) continue;

      if (line[0] == ';')
      {
        filename = line.substr(19);
        continue;
      }

      size_t pos = 0;
        int lineNumber = std::stoi(line, &pos);
        int address = 0;
        try
        {
          address = std::stoi(line.substr(pos), &pos, 16);
        }
        catch (...)
        {

        }

        source[filename].resize(lineNumber + 1);
        source[filename][lineNumber] = line.substr(32);
      
        if (address)
        {
          addrMap[address] = std::make_pair(filename, lineNumber);
        }
    }
  }
}


void debuggerInit(VrEmu6502* cpu6502_)
{
  cpu6502 = cpu6502_;
}

void debuggerInitTms(HBC56Device* tms)
{
  tms9918 = tms;
}

static uint8_t printable(uint8_t b)
{
  if (b < 0x20 || b > 0x7e)
  {
    return '.';
  }
  return b;
}


void constantTool(const char* name)
{
  auto iter = constants.find(name);
  bool found = iter != constants.end();
  uint16_t addr = 0;
  if (!found && name[0] == '$')
  {
    found = true;
    int val = 0;
    SDL_sscanf(name + 1, "%x", &val);
    addr = (uint16_t)val;
  }
  else if (found)
  {
    addr = iter->second;
  }

  if (found)
  {
    ImGui::BeginTooltip();
    ImGui::PushStyleColor(ImGuiCol_Text, ImVec4(1.0f, 1.0f, 1.0f, 1.0f));
    ImGui::TextUnformatted(name);
    ImGui::PopStyleColor();
    ImGui::PushStyleColor(ImGuiCol_Text, ImVec4(0.5f, 1.0f, 0.5f, 1.0f));
    ImGui::Separator();

    ImGui::PushStyleColor(ImGuiCol_Text, ImVec4(1.0f, 1.0f, 0.5f, 1.0f));
    ImGui::TextUnformatted("Hex: ");
    ImGui::PopStyleColor();
    ImGui::SameLine();
    if (addr < 0x100)
    {
      ImGui::Text("$%02x", addr);
    }
    else
    {
      ImGui::Text("$%04x", addr);
    }

    ImGui::PushStyleColor(ImGuiCol_Text, ImVec4(1.0f, 1.0f, 0.5f, 1.0f));
    ImGui::TextUnformatted("Dec: ");
    ImGui::PopStyleColor();
    ImGui::SameLine();
    ImGui::Text("%d", addr);

    ImGui::PushStyleColor(ImGuiCol_Text, ImVec4(1.0f, 1.0f, 0.5f, 1.0f));
    ImGui::TextUnformatted("Bin: ");
    ImGui::PopStyleColor();
    ImGui::SameLine();
    if (addr & 0xff00)
      ImGui::TextUnformatted(std::bitset<16>(addr).to_string().c_str());
    else
      ImGui::TextUnformatted(std::bitset<8>(addr).to_string().c_str());

    ImGui::PopStyleColor();
    ImGui::EndTooltip();

    if (ImGui::IsMouseClicked(0))
    {
      highlightAddr = addr;
      debugMemoryAddr = highlightAddr & 0xfff0;
    }
  }

}

void registerFlagValue(uint8_t val, uint8_t flag, char name)
{
  if (val & flag)
  {
    ImGui::Text("%c", toupper(name));
  }
  else
  {
    ImGui::PushStyleColor(ImGuiCol_Text, ImVec4(0.70f, 0.2f, 0.2f, 1.0f));
    ImGui::Text("%c", tolower(name));
    ImGui::PopStyleColor();
  }
  ImGui::SameLine();
}

void registersAddRow(const char* label, uint16_t value)
{
  ImGui::TableNextRow();
  ImGui::PushStyleColor(ImGuiCol_Text, ImVec4(1.0f, 1.0f, 0.5f, 1.0f));
  ImGui::TableSetColumnIndex(0);
  ImGui::TextUnformatted(label);
  ImGui::PopStyleColor();

  ImGui::PushStyleColor(ImGuiCol_Text, ImVec4(0.5f, 1.0f, 0.5f, 1.0f));
  ImGui::TableSetColumnIndex(1);
  if (value & 0xff00)
    ImGui::Text("$%04x", value);
  else
    ImGui::Text("$%02x", value);
  ImGui::TableSetColumnIndex(2);
  ImGui::Text("%d", value);
  ImGui::TableSetColumnIndex(3);
  if (label[1] == 'S')
  {
    ImGuiStyle& style = ImGui::GetStyle();
    ImGui::PushStyleVar(ImGuiStyleVar_ItemSpacing, ImVec2(0, (float)(int)(style.ItemSpacing.y)));
    registerFlagValue(value & 0xff, FlagN, 'N');
    registerFlagValue(value & 0xff, FlagV, 'V');
    registerFlagValue(value & 0xff, FlagU, 'U');
    registerFlagValue(value & 0xff, FlagB, 'B');
    registerFlagValue(value & 0xff, FlagD, 'D');
    registerFlagValue(value & 0xff, FlagI, 'I');
    registerFlagValue(value & 0xff, FlagZ, 'Z');
    registerFlagValue(value & 0xff, FlagC, 'C');
    ImGui::PopStyleVar(1);
  }
  else
  {
    if (value & 0xff00)
      ImGui::TextUnformatted("-");
    else
      ImGui::TextUnformatted(std::bitset<8>(value).to_string().c_str());
  }
  ImGui::PopStyleColor();
}

void debuggerRegistersView(bool* show)
{
  if (ImGui::Begin("Registers", show, ImGuiWindowFlags_HorizontalScrollbar))
  {
    if (ImGui::BeginTable("RegisterTable", 4, ImGuiTableFlags_SizingFixedFit | ImGuiTableFlags_Resizable))
    {
      ImGui::TableSetupColumn("Reg");
      ImGui::TableSetupColumn("Hex");
      ImGui::TableSetupColumn("Dec");
      ImGui::TableSetupColumn("Bin");
      ImGui::PushStyleColor(ImGuiCol_Text, ImVec4(1.0f, 1.0f, 0.5f, 1.0f));
      ImGui::TableHeadersRow();
      ImGui::PopStyleColor();

      registersAddRow("A", vrEmu6502GetAcc(cpu6502));
      registersAddRow("X", vrEmu6502GetX(cpu6502));
      registersAddRow("Y", vrEmu6502GetY(cpu6502));
      registersAddRow("PC", vrEmu6502GetPC(cpu6502));
      registersAddRow("SP", vrEmu6502GetStackPointer(cpu6502));
      registersAddRow("PS", vrEmu6502GetStatus(cpu6502));

      ImGui::EndTable();
    }
  }
  ImGui::End();
}

void debuggerStackView(bool* show)
{
  if (ImGui::Begin("Stack", show, ImGuiWindowFlags_HorizontalScrollbar))
  {
    ImGui::PushStyleColor(ImGuiCol_Text, ImVec4(0.5f, 1.0f, 0.5f, 1.0f));
    uint8_t sp = vrEmu6502GetStackPointer(cpu6502) + 1;
    while (sp != 0)
    {
      uint8_t d = hbc56MemRead(0x100 + sp, true);

      ImGui::PushStyleColor(ImGuiCol_Text, ImVec4(1.0f, 1.0f, 0.5f, 1.0f));
      ImGui::Text("$%04x", 0x100 + sp);
      ImGui::PopStyleColor();

      ImGui::SameLine();

      ImGui::Text("$%02x %03d", d, d);
      ++sp;
    }
    ImGui::PopStyleColor();
  }
  ImGui::End();
}

void debuggerDisassemblyView(bool* show)
{
  if (ImGui::Begin("Disassembly", show, ImGuiWindowFlags_HorizontalScrollbar))
  {
    uint16_t pc = vrEmu6502GetPC(cpu6502);
    ImGui::PushStyleColor(ImGuiCol_Text, ImVec4(0.5f, 1.0f, 0.5f, 1.0f));

    bool firstRow = true;

    while (ImGui::GetContentRegionAvail().y > ImGui::GetTextLineHeightWithSpacing())
    {
      if (pc == 0x00)
        break;

      if (labelMap[pc])
      {
        if (ImGui::GetContentRegionAvail().y < (ImGui::GetTextLineHeightWithSpacing() * 2)) break;

        ImGui::PushStyleColor(ImGuiCol_Text, ImVec4(0.5f, 0.5f, 1.0f, 1.0f));
        ImGui::TextUnformatted(labelMap[pc]);
        ImGui::PopStyleColor();
      }
      
      if (firstRow)
      {
        ImVec2 pos = ImGui::GetCursorScreenPos();
        ImVec2 max = pos;
        max.x += ImGui::GetContentRegionAvail().x - 1;
        max.y += ImGui::GetTextLineHeightWithSpacing();
        pos.x += 8;
        pos.y -= 1;
        ImGui::GetWindowDrawList()->AddRectFilled(pos, max, IM_COL32(0, 0, 255, 120));
        ImGui::GetWindowDrawList()->AddRect(pos, max, IM_COL32(0, 0, 255, 255));
        firstRow = false;
      }


      uint8_t opcode = hbc56MemRead(pc, true);
      ImGui::PushStyleColor(ImGuiCol_Text, ImVec4(1.0f, 1.0f, 0.5f, 1.0f));


      ImGui::Text("  $%04x", pc);
      ImGui::PopStyleColor();

      uint16_t refAddr = 0;
      char instructionBuffer[32];

      /* empty rom ? */
      if (opcode == 0xff && hbc56MemRead(pc + 1, true) == 0xff)
      {
        ++pc;
        instructionBuffer[0] = '-';
        instructionBuffer[1] = 0;
      }
      else
      {
        pc = vrEmu6502DisassembleInstruction(cpu6502, pc, sizeof(instructionBuffer), instructionBuffer, &refAddr, labelMap);
      }
      ImGui::SameLine();

      ImGui::TextUnformatted(instructionBuffer);

      if (refAddr && ImGui::IsItemHovered())
      {
        char tmpHex[10] = "$";
        _itoa(refAddr, tmpHex + 1, 16);
        constantTool(tmpHex);
      }

    }

    ImGui::PopStyleColor();
  }
  ImGui::End();
}

int outputToken(const char *token, const ImVec4 &color, int offset)
{
  ImGui::PushStyleColor(ImGuiCol_Text, color);
  ImGui::SameLine();
  if (offset > 0)
  {
    ImGui::Text("%*c%s", offset, ' ', token);
  }
  else
  {
    ImGui::TextUnformatted(token);
  }

  ImGui::PopStyleColor();

  return offset + strlen(token);
}



void debuggerSourceView(bool* show)
{
  if (ImGui::Begin("Source", show, ImGuiWindowFlags_HorizontalScrollbar))
  {
    uint16_t pc = vrEmu6502GetPC(cpu6502);

    //std::map<std::string, std::vector<std::string> > source;
    //std::map<int, std::pair<std::string, int> > addrMap;

    auto iter = addrMap.lower_bound(pc);
    if (iter != addrMap.end())
    {
      if (iter->first > pc) --iter;

      ImGui::TextUnformatted(iter->second.first.c_str());
      ImGui::Separator();

      auto &sourceVec = source.find(iter->second.first)->second;
      
      int lineNumber = iter->second.second;
      int highlightLineNumber = lineNumber;

      if (lineNumber > 5)
      {
        lineNumber -= 5;
      }
      
      ImGui::PushStyleColor(ImGuiCol_Text, ImVec4(0.7f, 0.7f, 0.7f, 1.0f));

      bool firstRow = true;

      uint16_t macroEnd = 0;

      while (ImGui::GetContentRegionAvail().y > ImGui::GetTextLineHeightWithSpacing() * 2)
      {
        
        if (lineNumber < sourceVec.size())
        {

          if (lineNumber == highlightLineNumber)
          {
            ImVec2 pos = ImGui::GetCursorScreenPos();
            ImVec2 max = pos;
            max.x += 1000;
            max.y += ImGui::GetTextLineHeightWithSpacing();
            pos.x -= 4;
            pos.y -= 1;
            ImGui::GetWindowDrawList()->AddRectFilled(pos, max, IM_COL32(0, 0, 255, 120));
            ImGui::GetWindowDrawList()->AddRect(pos, max, IM_COL32(0, 0, 255, 255));
          }


          ImGui::PushStyleColor(ImGuiCol_Text, ImVec4(1.0f, 1.0f, 0.5f, 1.0f));
          ImGui::Text("%-5d",lineNumber);
          ImGui::PopStyleColor();

          ImGuiStyle& style = ImGui::GetStyle();
          ImGui::PushStyleVar(ImGuiStyleVar_ItemSpacing, ImVec2(0, (float)(int)(style.ItemSpacing.y)));

          std::string code = sourceVec[lineNumber];
          char *token = strtok(&code[0], " \t\r\n");
          int lastPos = 0;

          std::string currentToken;
          bool inComment = false;
          bool firstToken = true;


          while (token)
          {
            if (token[0] == ';') // comment
            {
              outputToken(sourceVec[lineNumber].c_str() + lastPos, ImVec4(0.5f, 1.0f, 0.5f, 1.0f), 0);
              break;
            }
            else if (token == &code[0]) // label
            {
              lastPos += outputToken(token, ImVec4(0.5f, 0.5f, 1.0f, 1.0f), (token - &code[0]) - lastPos);
              if (ImGui::IsItemHovered())
              {
                ImGui::BeginTooltip();
                ImGui::TextUnformatted("Label");
                ImGui::EndTooltip();
              }
            }
            else if (firstToken  && token[0] == '+') // macro
            {
              lastPos += outputToken(token, ImVec4(0.5f, 1.0f, 1.0f, 1.0f), (token - &code[0]) - lastPos);
              auto next = iter;
              macroEnd = (++next)->first;
            }
            else if (token[0] == '#') // immediate
            {
              lastPos += outputToken(token, ImVec4(1.0f, 0.5f, 0.5f, 1.0f), (token - &code[0]) - lastPos);
              if (ImGui::IsItemHovered())
              {
                constantTool(token+1);
              }
            }
            else if (opcodes.find(token) != opcodes.end())
            {
              lastPos += outputToken(token, ImVec4(1.0f, 0.5f, 1.0f, 1.0f), (token - &code[0]) - lastPos);
            }
            else if (constants.find(token) != constants.end())
            {
              lastPos += outputToken(token, ImVec4(1.0f, 0.75f, 0.5f, 1.0f), (token - &code[0]) - lastPos);
              if (ImGui::IsItemHovered())
              {
                constantTool(token);
              }
            }
            else
            {
              lastPos += outputToken(token, ImVec4(0.5f, 0.5f, 0.5f, 1.0f), (token - &code[0]) - lastPos);
            }

            firstToken = false;
            token = strtok(NULL, " \t\r\n");
          }

          ImGui::PopStyleVar();

          ++lineNumber;
        }
        else
        {
          break;
        }
      }
      ImGui::PopStyleColor();
    }
  }
  ImGui::End();
}


void debuggerMemoryView(bool* show)
{
  if (ImGui::Begin("Memory", show, ImGuiWindowFlags_HorizontalScrollbar))
  {
    if (ImGui::IsWindowHovered()) {
      debugMemoryAddr -= ImGui::GetIO().MouseWheel * 0x40;
    }

    ImGui::PushStyleColor(ImGuiCol_Text, ImVec4(0.5f, 1.0f, 0.5f, 1.0f));

    uint16_t addr = debugMemoryAddr;
    while (ImGui::GetContentRegionAvail().y > ImGui::GetTextLineHeight())
    {
      uint8_t v0 = hbc56MemRead(addr, true);
      uint8_t v1 = hbc56MemRead(addr + 1, true);
      uint8_t v2 = hbc56MemRead(addr + 2, true);
      uint8_t v3 = hbc56MemRead(addr + 3, true);
      uint8_t v4 = hbc56MemRead(addr + 4, true);
      uint8_t v5 = hbc56MemRead(addr + 5, true);
      uint8_t v6 = hbc56MemRead(addr + 6, true);
      uint8_t v7 = hbc56MemRead(addr + 7, true);

      ImGui::PushStyleColor(ImGuiCol_Text, ImVec4(1.0f, 1.0f, 0.5f, 1.0f));
      ImGui::Text("$%04x", addr);
      ImGui::PopStyleColor();

      ImGui::SameLine();

      if ((highlightAddr & 0xfff8) == addr)
      {
        ImVec2 pos = ImGui::GetCursorScreenPos();
        ImVec2 max = pos;
        max.y += ImGui::GetTextLineHeightWithSpacing();
        pos.x += (highlightAddr & 0x07) * 21;
        max.x = pos.x + 17;
        pos.x -= 3;
        pos.y -= 1;
        ImGui::GetWindowDrawList()->AddRectFilled(pos, max, IM_COL32(255, 255, 0, 120));
        ImGui::GetWindowDrawList()->AddRect(pos, max, IM_COL32(255, 255, 0, 255));
      }

      ImGui::Text("%02x %02x %02x %02x %02x %02x %02x %02x %c%c%c%c%c%c%c%c",
        v0, v1, v2, v3, v4, v5, v6, v7,
        printable(v0), printable(v1), printable(v2), printable(v3),
        printable(v4), printable(v5), printable(v6), printable(v7));


      addr += 8;
    }

    ImGui::PopStyleColor();
  }
  ImGui::End();
}


void debuggerVramMemoryView(bool* show)
{
  if (ImGui::Begin("TMS9918A VRAM", show, ImGuiWindowFlags_HorizontalScrollbar))
  {
    if (ImGui::IsWindowHovered()) {
      debugTmsMemoryAddr -= ImGui::GetIO().MouseWheel * 0x40;
    }

    if (tms9918)
    {
      ImGui::PushStyleColor(ImGuiCol_Text, ImVec4(0.5f, 1.0f, 0.5f, 1.0f));

      uint16_t addr = debugTmsMemoryAddr & 0x3fff;
      while (ImGui::GetContentRegionAvail().y > ImGui::GetTextLineHeight())
      {
        uint8_t v0 = readTms9918Vram(tms9918, addr);
        uint8_t v1 = readTms9918Vram(tms9918, (addr + 1) & 0x3fff);
        uint8_t v2 = readTms9918Vram(tms9918, (addr + 2) & 0x3fff);
        uint8_t v3 = readTms9918Vram(tms9918, (addr + 3) & 0x3fff);
        uint8_t v4 = readTms9918Vram(tms9918, (addr + 4) & 0x3fff);
        uint8_t v5 = readTms9918Vram(tms9918, (addr + 5) & 0x3fff);
        uint8_t v6 = readTms9918Vram(tms9918, (addr + 6) & 0x3fff);
        uint8_t v7 = readTms9918Vram(tms9918, (addr + 7) & 0x3fff);

        ImGui::PushStyleColor(ImGuiCol_Text, ImVec4(1.0f, 1.0f, 0.5f, 1.0f));
        ImGui::Text("$%04x", addr);
        ImGui::PopStyleColor();

        ImGui::SameLine();

        ImGui::Text("%02x %02x %02x %02x %02x %02x %02x %02x %c%c%c%c%c%c%c%c",
          v0, v1, v2, v3, v4, v5, v6, v7,
          printable(v0), printable(v1), printable(v2), printable(v3),
          printable(v4), printable(v5), printable(v6), printable(v7));

        addr += 8;
      }

      ImGui::PopStyleColor();

    }
    else
    {
      ImGui::Text("TMS9918A not present");
    }
  }
  ImGui::End();
}

static std::string tmsColorText(uint8_t c)
{
  switch (c)
  {
    case TMS_TRANSPARENT:
      return "TRANSP";
    case TMS_BLACK:
      return "BLACK";
    case TMS_MED_GREEN:
      return "MED GREEN";
    case TMS_LT_GREEN:
      return "LT GREEN";
    case TMS_DK_BLUE:
      return "DK BLUE";
    case TMS_LT_BLUE:
      return "LT BLUE";
    case TMS_DK_RED:
      return "DK RED";
    case TMS_CYAN:
      return "CYAN";
    case TMS_MED_RED:
      return "MED RED";
    case TMS_LT_RED:
      return "LT RED";
    case TMS_DK_YELLOW:
      return "DK YEL";
    case TMS_LT_YELLOW:
      return "LT YEL";
    case TMS_DK_GREEN:
      return "GK GREEN";
    case TMS_MAGENTA:
      return "MAGENTA";
    case TMS_GREY:
      return "GREY";
    case TMS_WHITE:
      return "WHITE";
    default:
      return "ERR";
  }
}


void debuggerTmsRegistersView(bool* show)
{
  if (ImGui::Begin("TMS9918A Reg", show, ImGuiWindowFlags_HorizontalScrollbar))
  {
    if (tms9918)
    {
      ImGui::PushStyleColor(ImGuiCol_Text, ImVec4(0.5f, 1.0f, 0.5f, 1.0f));
      std::string desc;

      for (uint8_t y = 0; y < 8; ++y)
      {
        uint8_t r = readTms9918Reg(tms9918, y);
        uint16_t addr = 0xffff;
        desc.clear();
        switch (y)
        {
          case 0:
            if (r & TMS_R0_MODE_GRAPHICS_II) desc += "GFXII ";
            if (r & TMS_R0_EXT_VDP_ENABLE) desc += "EXTVDP ";
            break;

          case 1:
            desc = (r & TMS_R1_RAM_16K) ? "16KB " : "4KB ";
            desc += (r & TMS_R1_DISP_ACTIVE) ? "ON " : "OFF ";
            desc += (r & TMS_R1_INT_ENABLE) ? "INT " : "NOINT ";
            desc += (r & TMS_R1_MODE_MULTICOLOR) ? "MC " : ((r & TMS_R1_MODE_TEXT) ? "TXT " : "");
            desc += (r & TMS_R1_SPRITE_16) ? "SPR16 " : "SPR8 ";
            desc += (r & TMS_R1_SPRITE_MAG2) ? "MAG" : "";
            break;

          case 2:
            desc += "NAME";
            addr = r << 10;
            break;
          case 3:
            desc += "COLOR";
            addr = r << 6;
            break;
          case 4:
            desc += "PATT";
            addr = r << 11;
            break;
          case 5:
            desc += "SPR ATTR";
            addr = r << 7;
            break;
          case 6:
            desc += "SPR PATT";
            addr = r << 11;
            break;
          case 7:
            desc += "COLOR: ";
            desc += tmsColorText(r >> 4) + " on ";
            desc += tmsColorText(r & 0x0f);
            break;
        }


        ImGui::PushStyleColor(ImGuiCol_Text, ImVec4(1.0f, 1.0f, 0.5f, 1.0f));
        ImGui::Text("R%d", y);
        ImGui::PopStyleColor();
        ImGui::SameLine();
        if (addr == 0xffff)
          ImGui::Text("$%02x %s", r, desc.c_str());
        else
          ImGui::Text("$%02x %s: $%04x ", r, desc.c_str(), addr);
      }

      ImGui::PopStyleColor();

    }
    else
    {
      ImGui::Text("TMS9918A not present");
    }
  }
  ImGui::End();
}

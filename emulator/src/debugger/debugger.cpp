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
#include "../devices/via_device.h"
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
static HBC56Device* via = NULL;

static char tmpBuffer[256] = {0};

static std::map<std::string, int> constants;

static uint16_t highlightAddr = 0;
static uint16_t hoveredAddr = 0;

static uint16_t highlightTmsAddr = 0;

static const float alpha = 0.85f;

static const ImVec4 white(1.0f, 1.0f, 1.0f, alpha);
static const ImVec4 green(0.5f, 0.9f, 0.5f, alpha);
static const ImVec4 yellow(0.9f, 0.9f, 0.5f, alpha);
static const ImVec4 dkred(0.8f, 0.2f, 0.2f, alpha);
static const ImVec4 ltblue(0.75f, 0.75f, 1.0f, alpha);
static const ImVec4 grey(0.25f, 0.25f, 0.25f, alpha);
static const ImVec4 teal(0.5f, 1.0f, 0.0f, alpha);
static const ImVec4 purple(1.0f, 0.5f, 1.0f, alpha);
static const ImVec4 blue(0.5f, 0.5f, 1.0f, alpha);
static const ImVec4 red(1.0f, 0.5f, 0.5f, alpha);
static const ImVec4 ltred(1.0f, 0.75f, 0.5f, alpha);
static const ImVec4 dkteal(0.5f, 0.75f, 1.0f, alpha);
static const ImVec4 pink(1.0f, 0.75f, 1.0f, alpha);
static const ImVec4 ltgrey(0.7f, 0.7f, 0.7f, alpha);

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
      int len = (int)strlen(lineBuffer);
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

//std::map<std::string, std::vector<std::pair<std::string, uint16_t> > > source;
//std::map<int, std::pair<std::string, int> > addrMap;
std::set<std::string> opcodes;

bool isBranchingOpcode(const std::string& opcode)
{
  if (opcode.empty())
    return false;

  if (opcode[0] == 'b')
  {
    return opcode != "brk" && opcode != "bit";
  }

  return opcode == "jmp" || opcode == "jsr" || opcode == "rts" || opcode == "rti";
}


class Token
{
public:
  typedef std::shared_ptr<Token> Ptr;

  typedef enum
  {
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
    PSEUDOOP,
    UNKNOWN
  } Type;

  static Ptr Create(Token::Type type, const std::string& value)
  {
    return Ptr(new Token(type, value));
  }

  Token::Type type() const { return m_type; }
  const std::string& value() const { return m_value; }

private:
  Token(Token::Type type, const std::string& value)
    : m_type(type), m_value(value)
  {

  }

  Token::Type             m_type;
  std::string             m_value;
};

class SourceFile;

class SourceLine
{
public:
  SourceLine(SourceFile *file, const std::string& line, uint16_t addr = 0xffff) : m_file(file), m_addr(addr)
  {
    for (int i = 0; i < line.size(); ++i)
    {
      if (line[i] == ';')
      {
        addChild(Token::Create(Token::COMMENT, line.substr(i)));
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
        addChild(Token::Create(Token::STRING, line.substr(start, i - start)));
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
        addChild(Token::Create(Token::STRING, line.substr(start, i - start)));
        --i;
      }
      else if (isspace(line[i]))
      {
        size_t start = i;
        for (; i < line.size(); ++i)
        {
          if (!isspace(line[i])) break;
        }
        addChild(Token::Create(Token::WHITESPACE, line.substr(start, i - start)));
        --i;
      }
      else if (line[i] == ',')
      {
        addChild(Token::Create(Token::COMMA, line.substr(i, 1)));
      }
      else if (line[i] == '#')
      {
        addChild(Token::Create(Token::IMMEDIATE, line.substr(i, 1)));
      }
      else if (line[i] == '+' && (containsOnly(Token::WHITESPACE)))
      {
        size_t start = i++;
        for (; i < line.size(); ++i)
        {
          if (!isalnum(line[i]) && line[i] != '_' && line[i] <= 127) break;
        }
        addChild(Token::Create(i - start == 1 ? Token::CONSTANT : Token::MACRO, line.substr(start, i - start)));
        --i;
      }
      else if (line[i] == '!' && (containsOnly(Token::WHITESPACE)))
      {
        size_t start = i++;
        for (; i < line.size(); ++i)
        {
          if (!isalpha(line[i])) break;
        }
        addChild(Token::Create(Token::PSEUDOOP, line.substr(start, i - start)));
        --i;
      }
      else if (line[i] == '.' || line[i] == '@' || line[i] == '_' || isalpha(line[i]))
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

        addChild(Token::Create(type, word));
        --i;
      }
      else if (line[i] == '$' || (line[i] == '0' && line[i + 1] == 'x')) // hex
      {
        size_t start = i++;
        for (; i < line.size(); ++i)
        {
          if (!isxdigit(line[i])) break;
        }
        addChild(Token::Create(Token::NUMBER, line.substr(start, i - start)));
        --i;
      }
      else if (line[i] == '%' && (line[i + 1] == '0' || line[i + 1] == '1' || line[i + 1] == '#' || line[i + 1] == '.')) // binary
      {
        size_t start = i++;
        for (; i < line.size(); ++i)
        {
          if (line[i] != '0' && line[i] != '1' && line[i] != '.' && line[i] != '#') break;
        }
        addChild(Token::Create(Token::NUMBER, line.substr(start, i - start)));
        --i;
      }
      else if (line[i] == '&' && isdigit(line[i + 1])) // octal
      {
        size_t start = i++;
        for (; i < line.size(); ++i)
        {
          if (line[i] < '0' || line[i]  > '7') break;
        }
        addChild(Token::Create(Token::NUMBER, line.substr(start, i - start)));
        --i;
      }
      else if (isdigit(line[i]))
      {
        size_t start = i;
        for (; i < line.size(); ++i)
        {
          if (!isdigit(line[i]) && line[i] != '.') break;
        }
        addChild(Token::Create(Token::NUMBER, line.substr(start, i - start)));
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
          addChild(Token::Create(Token::OPERATOR, line.substr(start, i - start)));
          --i;
        }
        else
        {
          addChild(Token::Create(Token::UNKNOWN, line.substr(i, 1)));
        }
      }
    }
  }

  void setAddress(uint16_t addr) { m_addr = addr; }

  SourceFile *file() const { return m_file; }

  uint16_t address() const { return m_addr; }
  const std::vector<Token::Ptr> &children() const { return m_children; }

  std::vector<SourceLine>& macroLines() { return m_macroLines; }
  const std::vector<SourceLine>& macroLines() const { return m_macroLines; }

  bool contains(Token::Type type) const
  {
    for (const auto &node : m_children)
    {
      if (node->type() == type)
        return true;
    }
    return false;
  }

  Token::Ptr childOfType(Token::Type type) const
  {
    for (const auto& node : m_children)
    {
      if (node->type() == type)
        return node;
    }
    return nullptr;
  }


  bool containsOnly(Token::Type type) const
  {
    for (const auto& node : m_children)
    {
      if (node->type() != type)
        return false;
    }
    return true;
  }

private:
  void addChild(Token::Ptr child) { m_children.push_back(child); }

private:
  SourceFile             *m_file;
  uint16_t                m_addr;
  std::vector<Token::Ptr> m_children;
  std::vector<SourceLine> m_macroLines;


};


class SourceFile
{
  public:
    SourceFile(){}
    SourceFile(const std::string& filename) : m_filename(filename)
    {

    }

    void addLine(const std::string& line, uint16_t addr)
    {
      m_addrMap[addr] = (int)m_lines.size();
      m_lines.push_back(SourceLine(this, line, addr));

      if (addr != 0xffff)
      {
        for (int i = (int)m_lines.size() - 2; i >= 0; --i)
        {
          if (m_lines[i].address() == 0xffff)
          {
            m_lines[i].setAddress(addr);

            if (m_lines[i].contains(Token::LABEL) && constants.find(m_lines[i].childOfType(Token::LABEL)->value()) == constants.end())
            {
              if (!m_lines[i].contains(Token::OPERATOR))
                constants[m_lines[i].childOfType(Token::LABEL)->value()] = addr;
            }
          }
          else
          {
            if (m_lines[i].contains(Token::MACRO))
            {
              uint16_t fromAddress = m_lines[i].address();
              uint16_t toAddress = addr;

              uint16_t tmpAddress = fromAddress;
              char instructionBuffer[32];
              while (tmpAddress < toAddress)
              {
                uint16_t refAddr = 0;
                uint16_t prevTmpAddress = tmpAddress;
                tmpAddress = vrEmu6502DisassembleInstruction(cpu6502, tmpAddress, sizeof(instructionBuffer), instructionBuffer, &refAddr, labelMap);
                m_lines[i].macroLines().push_back(SourceLine(nullptr, instructionBuffer, prevTmpAddress));
              }
            }
            break;
          }
        }
      }
    }

    const std::string &filename() const { return m_filename; }

    int numLines() const { return (int)m_lines.size(); }
    const SourceLine& line(size_t index) const {
      return m_lines[index];
    }

    int lineIndex(uint16_t addr) const {
      auto iter = m_addrMap.lower_bound(addr);
      if (iter == m_addrMap.end()) return -1;
      if (iter->first == addr)
      {
        return iter->second;
      }
      if (iter == m_addrMap.begin()) return -1;

      --iter;
      if (addr - iter->first < 50)
        return iter->second;
      return -1;
    }

  private:
    std::string m_filename;
    std::vector<SourceLine> m_lines;
    std::map<uint16_t, int> m_addrMap;
};


class Source
{
public:
  SourceFile& file(const std::string& filename)
  {
    auto iter = m_files.find(filename);
    if (iter == m_files.end())
    {
      m_files[filename] = SourceFile(filename);
      return m_files[filename];
    }
    return iter->second;
  }

  const SourceFile& file(uint16_t addr)
  {
    if (m_addrMap.empty())
    {
      int fileIndex = 0;
      for (auto iter = m_files.begin(); iter != m_files.end(); ++iter, ++fileIndex)
      {
        for (int i = 0; i < iter->second.numLines(); ++i)
        {
          m_addrMap[iter->second.line(i).address()] = fileIndex;
        }
      }
    }

    static SourceFile nullFile("");

    auto iter = m_addrMap.lower_bound(addr);
    if (iter == m_addrMap.end()) return nullFile;

    return fileFromIndex(iter->second);
  }

  const SourceFile& fileFromIndex(size_t index) const {
    auto iter = m_files.begin();
    std::advance(iter, index);
    return iter->second;
  }

  int numFiles() const { return (int)m_files.size(); }
  int index(const std::string& filename)
  {
    int i = 0;
    for (auto iter = m_files.begin(); iter != m_files.end(); ++iter, ++i)
    {
      if (iter->first == filename)
        return i;
    }
    return -1;
  }

  void clear()
  {
    m_addrMap.clear();
    m_files.clear();
  }

  private:
    std::map<uint16_t, size_t> m_addrMap;
    std::map<std::string, SourceFile> m_files;
};

Source source;
bool sourceLoading = false;

void debuggerLoadSource(const char* rptFileContents)
{
  sourceLoading = true;
  source.clear();

  for (int i = 0; i < 256; ++i)
  {
    opcodes.insert(vrEmu6502OpcodeToMnemonicStr(cpu6502, i & 0xff));
  }

  if (rptFileContents)
  {

    char* p = (char*)rptFileContents;
    SourceFile *currentFile = nullptr;

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
        currentFile = &source.file(line.substr(19));
        continue;
      }

      int lineNumber = 0;
      int address = 0xffff;
      SDL_sscanf(line.c_str(), "%6d  %4x", &lineNumber, &address);

      currentFile->addLine(line.substr(32), address & 0xffff);
    }
  }
  sourceLoading = false;
}


void debuggerInit(VrEmu6502* cpu6502_)
{
  cpu6502 = cpu6502_;
}

void debuggerInitTms(HBC56Device* tms)
{
  tms9918 = tms;
}

void debuggerInitVia(HBC56Device* via6522)
{
  via = via6522;
}


std::set<uint16_t> breakpoints;

uint8_t debuggerIsBreakpoint(uint16_t addr)
{
  return breakpoints.find(addr) != breakpoints.end();
}

void toggleBreakpoint(uint16_t addr)
{
  auto iter = breakpoints.find(addr);
  if (iter == breakpoints.end())
  {
    breakpoints.insert(addr);
  }
  else
  {
    breakpoints.erase(iter);
  }
}

static uint8_t printable(uint8_t b)
{
  if (b < 0x20 || b > 0x7e)
  {
    return '.';
  }
  return b;
}



static int currentFile = 0;
static uint16_t lastPc = 0;
static int lastLineNumber = 0;
static int macroOffset = 0;
static int macroLines = 0;

static float scrollPos = -1.0f;


void setSourceAddress(uint16_t addr)
{
  auto f = source.file(addr);

  int lineIndex = f.lineIndex(addr);

  if (lineIndex >= 0)
  {
    while (lineIndex && f.line(lineIndex--).address() == addr)
    {
      if (f.line(lineIndex + 1).contains(Token::LABEL))
      {
        currentFile = source.index(f.filename());
        lastLineNumber = f.lineIndex(addr) + 1;
        scrollPos = (lastLineNumber + macroOffset) * ImGui::GetTextLineHeightWithSpacing();
      }
    }
  }
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
    addr = (uint16_t)iter->second;
  }

  if (found)
  {
    uint8_t memVal = hbc56MemRead(addr, true);

    ImGui::BeginTooltip();
    ImGui::PushStyleColor(ImGuiCol_Text, white);
    ImGui::TextUnformatted(name);
    ImGui::PopStyleColor();
    ImGui::PushStyleColor(ImGuiCol_Text, green);
    ImGui::Separator();

    ImGui::PushStyleColor(ImGuiCol_Text, yellow);
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
    ImGui::SameLine();
    ImGui::Text(" -> $%02x", memVal);

    ImGui::PushStyleColor(ImGuiCol_Text, yellow);
    ImGui::TextUnformatted("Dec: ");
    ImGui::PopStyleColor();
    ImGui::SameLine();
    ImGui::Text("%d", addr);
    ImGui::SameLine();
    ImGui::Text(" -> %d", memVal);

    ImGui::PushStyleColor(ImGuiCol_Text, yellow);
    ImGui::TextUnformatted("Bin: ");
    ImGui::PopStyleColor();
    ImGui::SameLine();
    if (addr & 0xff00)
      ImGui::TextUnformatted(std::bitset<16>(addr).to_string().c_str());
    else
      ImGui::TextUnformatted(std::bitset<8>(addr).to_string().c_str());

    hoveredAddr = addr;

    ImGui::PopStyleColor();
    ImGui::EndTooltip();

    if (ImGui::IsMouseClicked(0))
    {
      highlightAddr = addr;
      debugMemoryAddr = highlightAddr & 0xfff0;

      setSourceAddress(addr);
    }
  }
}

std::string toStrBinary(uint8_t byte) {
  std::string out = "0b";
  for (int i = 0; i < 8; ++i, byte<<=1) {
    out += (byte & 0x80) ? "1" : "0";
  }
  return out;
}

void patternTool(int pattIdx, uint16_t addr, SDL_Texture*tex, ImVec2 uv0, ImVec2 uv1)
{
  if (ImGui::IsMouseClicked(0))
  {
    highlightTmsAddr = addr;
    debugTmsMemoryAddr = highlightTmsAddr & 0xfff0;
  }

  ImGui::BeginTooltip();
  ImGui::PushStyleColor(ImGuiCol_Text, white);
  ImGui::Text("Index: %d $%02x", pattIdx, pattIdx);
  ImGui::PopStyleColor();
  ImGui::SameLine();
  ImGui::PushStyleColor(ImGuiCol_Text, green);
  ImGui::Text("Address: $%04x", addr);
  ImGui::Separator();
  ImGui::Text("");
  ImGui::Image(tex, ImVec2(128, 128), uv0, uv1);
  ImGui::SameLine();
  ImGui::SetCursorPosY(ImGui::GetCursorPosY() - 20);
  ImGui::PushStyleVar(ImGuiStyleVar_CellPadding, ImVec2(5, 2));
  if (ImGui::BeginTable("Values", 4, ImGuiTableFlags_SizingFixedFit))
  {
    ImGui::TableSetupColumn("Bin");
    ImGui::TableSetupColumn("Hex");
    ImGui::PushStyleColor(ImGuiCol_Text, yellow);
    ImGui::TableHeadersRow();
    ImGui::PopStyleColor();

    for (int i = 0; i < 8; ++i)
    {
      ImGui::TableNextRow();
      
      uint8_t pattByte = readTms9918Vram(tms9918, (addr + i) & 0x3fff);
      ImGui::TableSetColumnIndex(0);
      ImGui::TextUnformatted(toStrBinary(pattByte).c_str());
      ImGui::TableSetColumnIndex(1);
      ImGui::Text("$%02x", pattByte);
    }

    ImGui::EndTable();
  }
  ImGui::PopStyleVar();

  ImGui::PopStyleColor();
  ImGui::EndTooltip();
}

void registerFlagValue(uint8_t val, uint8_t flag, char name)
{
  if (val & flag)
  {
    ImGui::Text("%c", toupper(name));
  }
  else
  {
    ImGui::PushStyleColor(ImGuiCol_Text, dkred);
    ImGui::Text("%c", tolower(name));
    ImGui::PopStyleColor();
  }
  ImGui::SameLine();
}

void registersAddRow(const char* label, uint16_t value)
{
  ImGui::TableNextRow();
  ImGui::PushStyleColor(ImGuiCol_Text, yellow);
  ImGui::TableSetColumnIndex(0);
  ImGui::TextUnformatted(label);
  ImGui::PopStyleColor();

  ImGui::PushStyleColor(ImGuiCol_Text, green);
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
      ImGui::PushStyleColor(ImGuiCol_Text, yellow);
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
    ImGui::PushStyleColor(ImGuiCol_Text, green);
    uint8_t sp = vrEmu6502GetStackPointer(cpu6502) + 1;
    while (sp != 0)
    {
      uint8_t d = hbc56MemRead(0x100 + sp, true);

      ImGui::PushStyleColor(ImGuiCol_Text, yellow);
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


void renderLine(const SourceLine &line)
{

  ImGuiStyle& style = ImGui::GetStyle();
  ImGui::PushStyleVar(ImGuiStyleVar_ItemSpacing, ImVec2(0, (float)(int)(style.ItemSpacing.y)));
  ImGui::PushStyleColor(ImGuiCol_Text, grey);

  auto label = line.childOfType(Token::LABEL);

  for (const auto& tok : line.children())
  {
    int hasColor = true;

    switch (tok->type())
    {
    case Token::COMMENT:
      ImGui::PushStyleColor(ImGuiCol_Text, teal);
      break;
    case Token::OPCODE:
      if (isBranchingOpcode(tok->value()))
        ImGui::PushStyleColor(ImGuiCol_Text, purple);
      else
        ImGui::PushStyleColor(ImGuiCol_Text, blue);
      break;
    case Token::NUMBER:
      ImGui::PushStyleColor(ImGuiCol_Text, red);
      break;
    case Token::STRING:
      ImGui::PushStyleColor(ImGuiCol_Text, ltred);
      break;
    case Token::OPERATOR:
      ImGui::PushStyleColor(ImGuiCol_Text, green);
      break;
    case Token::IMMEDIATE:
      ImGui::PushStyleColor(ImGuiCol_Text, blue);
      break;
    case Token::MACRO:
      ImGui::PushStyleColor(ImGuiCol_Text, ltblue);
      break;
    case Token::CONSTANT:
      ImGui::PushStyleColor(ImGuiCol_Text, yellow);
      break;
    case Token::LABEL:
      ImGui::PushStyleColor(ImGuiCol_Text, dkteal);
      break;
    case Token::PSEUDOOP:
      ImGui::PushStyleColor(ImGuiCol_Text, pink);
      break;
    default:
      hasColor = false;
      break;
    }

    ImGui::SameLine();
    ImGui::TextUnformatted(tok->value().c_str());
    if (ImGui::IsItemHovered())
    {
      if (tok->type() == Token::CONSTANT || tok->type() == Token::LABEL || tok->type() == Token::NUMBER)
      {
        constantTool(tok->value().c_str());
      }
      else
      {
        hoveredAddr = 0xffff;
      }
    }


    if (hasColor)
    {
      ImGui::PopStyleColor();
    }
  }

  ImGui::PopStyleColor();
  ImGui::PopStyleVar();
}

void highlightRow()
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

void highlightRowBreakpoint()
{
  ImVec2 pos = ImGui::GetCursorScreenPos();
  ImVec2 max = pos;
  max.x += 1000;
  max.y += ImGui::GetTextLineHeightWithSpacing();
  pos.x -= 4;
  pos.y -= 1;
  ImGui::GetWindowDrawList()->AddRectFilled(pos, max, IM_COL32(255, 0, 0, 120));
  ImGui::GetWindowDrawList()->AddRect(pos, max, IM_COL32(255, 0, 0, 255));
}

void highlightRowHovered()
{
  ImVec2 pos = ImGui::GetCursorScreenPos();
  ImVec2 max = pos;
  max.x += 1000;
  max.y += ImGui::GetTextLineHeightWithSpacing();
  pos.x -= 4;
  pos.y -= 1;
  ImGui::GetWindowDrawList()->AddRectFilled(pos, max, IM_COL32(0, 255, 0, 120));
  ImGui::GetWindowDrawList()->AddRect(pos, max, IM_COL32(0, 255, 0, 255));
}



void debuggerDisassemblyView(bool* show)
{
  if (ImGui::Begin("Disassembly", show, ImGuiWindowFlags_HorizontalScrollbar))
  {
    uint16_t pc = vrEmu6502GetPC(cpu6502);
    ImGui::PushStyleColor(ImGuiCol_Text, green);

    bool firstRow = true;

    while (ImGui::GetContentRegionAvail().y > ImGui::GetTextLineHeightWithSpacing())
    {
      if (pc == 0x00)
        break;

      if (labelMap[pc])
      {
        if (ImGui::GetContentRegionAvail().y < (ImGui::GetTextLineHeightWithSpacing() * 2)) break;

        ImGui::PushStyleColor(ImGuiCol_Text, blue);
        ImGui::TextUnformatted(labelMap[pc]);
        ImGui::PopStyleColor();
      }
      
      if (firstRow)
      {
        highlightRow();
        firstRow = false;
      }
      else if (debuggerIsBreakpoint(pc))
      {
        highlightRowBreakpoint();
      }
      else if (hoveredAddr == pc)
      {
        highlightRowHovered();
      }

      uint8_t opcode = hbc56MemRead(pc, true);
      ImGui::PushStyleColor(ImGuiCol_Text, yellow);


      ImGui::Text("  $%04x ", pc);
      ImGui::PopStyleColor();

      if (ImGui::IsItemClicked())
      {
        toggleBreakpoint(pc);
      }

      uint16_t refAddr = 0;
      char instructionBuffer[32];
      uint16_t currentPc = pc;

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

      renderLine(SourceLine(nullptr, instructionBuffer, currentPc));
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

  return offset + (int)strlen(token);
}



static bool Items_FileGetter(void* data, int idx, const char** out_text)
{
  auto *fileMap = (Source*)data;

  if (out_text && idx >= 0)
    *out_text = fileMap->fileFromIndex(idx).filename().c_str();

  return true;
}


void debuggerSourceView(bool* show)
{
  if (ImGui::Begin("Source", show, ImGuiWindowFlags_HorizontalScrollbar))
  {
    uint16_t pc = vrEmu6502GetPC(cpu6502);

    //std::map<std::string, std::vector<std::pair<std::string, uint16_t>> > source;   filename, vector of lines/addresses
    //std::map<int, std::pair<std::string, int> > addrMap;       address, filename, line 

    const SourceFile& activeFile = source.file(pc);

    if (pc != lastPc)
    {
      lastPc = pc;
      macroOffset = 0;
      macroLines = 0;
      currentFile = source.index(activeFile.filename());

      lastLineNumber = activeFile.lineIndex(pc) + 1;

      if (lastLineNumber)
      {
        auto sourceLine = activeFile.line(lastLineNumber - 1);

        macroLines = (int)sourceLine.macroLines().size();
        if (macroLines)
        {
          for (int i = 0; i < macroLines; ++i)
          {
            if (sourceLine.macroLines()[i].address() == pc)
            {
              macroOffset = i + 1;
              break;
            }
          }
        }
      }
      scrollPos = (lastLineNumber + macroOffset) * ImGui::GetTextLineHeightWithSpacing();
    }

    if (ImGui::Combo(" ", &currentFile, Items_FileGetter, &source, source.numFiles(), 8))
    {
      lastLineNumber = 1;
    }

    if (currentFile >= 0)
    {
      const SourceFile& visibleFile = source.fileFromIndex(currentFile);
      if (!visibleFile.filename().empty())
      {
        int highlightLineNumber = activeFile.lineIndex(pc) + 1;

        if (&visibleFile != &activeFile) highlightLineNumber = -1;

        ImGui::Separator();

        ImGui::BeginChild("code", ImVec2(), false, ImGuiWindowFlags_HorizontalScrollbar);

        if (ImGui::IsWindowHovered()) {
          lastLineNumber -= (int)(ImGui::GetIO().MouseWheel * 3.0f);
          if (lastLineNumber <= 0) lastLineNumber = 1;
        }

        ImGuiListClipper clipper;
        clipper.Begin(visibleFile.numLines());


        ImGui::PushStyleColor(ImGuiCol_Text, ltgrey);

        while (clipper.Step())
        {
          for (int i = clipper.DisplayStart; i < clipper.DisplayEnd; i++)
          {
            int lineNumber = i + 1;

            bool activeRow = lineNumber == highlightLineNumber;

            const SourceLine& line = visibleFile.line(i);

            if (activeRow)
            {
              highlightRow();
            }
          
            if (debuggerIsBreakpoint(line.address()) && (line.contains(Token::OPCODE) || line.contains(Token::MACRO)))
            {
              highlightRowBreakpoint();
            }

            if (hoveredAddr == line.address() && line.contains(Token::LABEL) && !line.contains(Token::OPERATOR))
            {
              highlightRowHovered();
            }

            ImGui::PushStyleColor(ImGuiCol_Text, yellow);
            ImGui::Text(" %-5d", lineNumber);
            ImGui::PopStyleColor();

            if (ImGui::IsItemClicked() || (activeRow && ImGui::IsKeyPressed(ImGuiKey_F9)))
            {
              toggleBreakpoint(line.address());
            }

            renderLine(line);

            if (activeRow)
            {
              for (int j = 0; j < line.macroLines().size(); ++j)
              {
                if (line.macroLines()[j].address() == pc)
                  highlightRow();

                ImGui::TextUnformatted("                  ");
                renderLine(line.macroLines()[j]);
              }
            }
            else if (activeRow)
            {
              macroOffset = 0;
            }
          }
        }
        ImGui::PopStyleColor();
        if (scrollPos >= 0.0f)
        {
          ImGui::SetScrollY(scrollPos - ImGui::GetWindowHeight() * 0.25f);
          scrollPos = -1.0f;
        }
        ImGui::EndChild();
      }
    }
  }
  ImGui::End();
}


void debuggerBreakpointsView(bool* show)
{
  if (ImGui::Begin("Breakpoints", show, ImGuiWindowFlags_HorizontalScrollbar))
  {
    if (ImGui::BeginTable("BreakpointsTable", 3, ImGuiTableFlags_SizingFixedFit | ImGuiTableFlags_Resizable))
    {
      ImGui::TableSetupColumn("File");
      ImGui::TableSetupColumn("Line");
      ImGui::TableSetupColumn("Address");
      ImGui::PushStyleColor(ImGuiCol_Text, yellow);
      ImGui::TableHeadersRow();
      ImGui::PopStyleColor();

      for (uint16_t addr : breakpoints)
      {
        auto file = source.file(addr);
        int lineIndex = file.lineIndex(addr);
        if (lineIndex < 0) continue;
        auto line = file.line(lineIndex);

        ImGui::TableNextRow();


        ImGui::PushStyleColor(ImGuiCol_Text, yellow);
        ImGui::TableSetColumnIndex(0);
        if (ImGui::SmallButton("..."))
        {
          setSourceAddress(addr);
        }
        ImGui::SameLine();
        ImGui::TextUnformatted(file.filename().c_str());
        ImGui::PopStyleColor();

        ImGui::PushStyleColor(ImGuiCol_Text, green);
        ImGui::TableSetColumnIndex(1);
        ImGui::Text("%d", lineIndex + 1);
        ImGui::TableSetColumnIndex(2);
        ImGui::Text("%04x", addr);

        ImGui::PopStyleColor();
      }
      ImGui::EndTable();
    }
  }
  ImGui::End();
}



void debuggerMemoryView(bool* show)
{
  static int lastDebugMemoryAddr = 0;

  if (ImGui::Begin("Memory", show, ImGuiWindowFlags_HorizontalScrollbar))
  {
    const int numLines = 0x10000 >> 3;

    ImGuiListClipper clipper;
    clipper.Begin(numLines);

    if (lastDebugMemoryAddr != debugMemoryAddr)
    {
      scrollPos = (debugMemoryAddr >> 3) * ImGui::GetTextLineHeightWithSpacing();
      ImGui::SetScrollY(scrollPos);
      lastDebugMemoryAddr = debugMemoryAddr;
    }

    ImGui::PushStyleColor(ImGuiCol_Text, green);

    while (clipper.Step())
    {
      for (int i = clipper.DisplayStart; i < clipper.DisplayEnd; i++)
      {
        uint16_t addr = (i * 8) & 0xffff;

        uint8_t v0 = hbc56MemRead(addr, true);
        uint8_t v1 = hbc56MemRead(addr + 1, true);
        uint8_t v2 = hbc56MemRead(addr + 2, true);
        uint8_t v3 = hbc56MemRead(addr + 3, true);
        uint8_t v4 = hbc56MemRead(addr + 4, true);
        uint8_t v5 = hbc56MemRead(addr + 5, true);
        uint8_t v6 = hbc56MemRead(addr + 6, true);
        uint8_t v7 = hbc56MemRead(addr + 7, true);

        ImGui::PushStyleColor(ImGuiCol_Text, yellow);
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
          ImGui::GetWindowDrawList()->AddRectFilled(pos, max, IM_COL32(000, 255, 0, 120));
          ImGui::GetWindowDrawList()->AddRect(pos, max, IM_COL32(000, 255, 0, 255));
        }

        if ((hoveredAddr & 0xfff8) == addr)
        {
          ImVec2 pos = ImGui::GetCursorScreenPos();
          ImVec2 max = pos;
          max.y += ImGui::GetTextLineHeightWithSpacing();
          pos.x += (hoveredAddr & 0x07) * 21;
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
      }
    }
    ImGui::PopStyleColor();
  }
  ImGui::End();
}


void debuggerVramMemoryView(bool* show)
{
  static int lastDebugMemoryAddr = 0;

  if (ImGui::Begin("TMS9918A VRAM", show, ImGuiWindowFlags_HorizontalScrollbar))
  {
    if (tms9918)
    {
      const int numLines = 0x4000 >> 3;

      ImGuiListClipper clipper;
      clipper.Begin(numLines);

      if (lastDebugMemoryAddr != debugTmsMemoryAddr)
      {
        scrollPos = (debugTmsMemoryAddr >> 3) * ImGui::GetTextLineHeightWithSpacing();
        ImGui::SetScrollY(scrollPos);
        lastDebugMemoryAddr = debugTmsMemoryAddr;
      }

      ImGui::PushStyleColor(ImGuiCol_Text, green);

      while (clipper.Step())
      {
        for (int i = clipper.DisplayStart; i < clipper.DisplayEnd; i++)
        {
          uint16_t addr = (i * 8) & 0x3fff;

          uint8_t v0 = readTms9918Vram(tms9918, addr);
          uint8_t v1 = readTms9918Vram(tms9918, (addr + 1) & 0x3fff);
          uint8_t v2 = readTms9918Vram(tms9918, (addr + 2) & 0x3fff);
          uint8_t v3 = readTms9918Vram(tms9918, (addr + 3) & 0x3fff);
          uint8_t v4 = readTms9918Vram(tms9918, (addr + 4) & 0x3fff);
          uint8_t v5 = readTms9918Vram(tms9918, (addr + 5) & 0x3fff);
          uint8_t v6 = readTms9918Vram(tms9918, (addr + 6) & 0x3fff);
          uint8_t v7 = readTms9918Vram(tms9918, (addr + 7) & 0x3fff);

          ImGui::PushStyleColor(ImGuiCol_Text, yellow);
          ImGui::Text("$%04x", addr);
          ImGui::PopStyleColor();

          ImGui::SameLine();

          if ((highlightTmsAddr & 0xfff8) == addr)
          {
            ImVec2 pos = ImGui::GetCursorScreenPos();
            ImVec2 max = pos;
            max.y += ImGui::GetTextLineHeightWithSpacing();
            pos.x += (highlightTmsAddr & 0x07) * 21;
            max.x = pos.x + 17;
            pos.x -= 3;
            pos.y -= 1;
            ImGui::GetWindowDrawList()->AddRectFilled(pos, max, IM_COL32(000, 255, 0, 120));
            ImGui::GetWindowDrawList()->AddRect(pos, max, IM_COL32(000, 255, 0, 255));
          }

          ImGui::Text("%02x %02x %02x %02x %02x %02x %02x %02x %c%c%c%c%c%c%c%c",
            v0, v1, v2, v3, v4, v5, v6, v7,
            printable(v0), printable(v1), printable(v2), printable(v3),
            printable(v4), printable(v5), printable(v6), printable(v7));

        }
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

void debuggerTmsPatternsView(SDL_Renderer* renderer, bool* show)
{
  static SDL_Texture* tex = NULL;
  vrEmuTms9918Mode mode = (vrEmuTms9918Mode)getTms9918Mode(tms9918);
  int tableColumns = ((mode == TMS_MODE_GRAPHICS_II) ? 33 : 17);
  int tableRows = ((mode == TMS_MODE_GRAPHICS_II) ? 25 : 17);

  ImGui::SetNextWindowContentSize(ImVec2(tableColumns * 26.0f, 0.0f));
  if (ImGui::Begin("TMS9918A Patterns", show, ImGuiWindowFlags_HorizontalScrollbar))
  {
    if (tms9918)
    {

      ImGui::PushStyleVar(ImGuiStyleVar_CellPadding, ImVec2(1,1));
      ImGui::BeginTable("PatternsTable", tableColumns, ImGuiTableFlags_SizingFixedFit | ImGuiTableFlags_NoBordersInBody);
      ImGui::PushStyleColor(ImGuiCol_Text, yellow);
      
      ImGui::TableNextRow();
      ImGui::TableSetColumnIndex(0);
      ImGui::TextUnformatted("$");

      for (int i = 1; i < tableColumns; ++i)
      {
        ImGui::TableSetColumnIndex(i);
        ImGui::Text("$%02x", (i - 1) * 8);
      }


      const int texSize = 256;

      if (tex == NULL)
      {
        tex = SDL_CreateTexture(renderer, SDL_PIXELFORMAT_RGBA8888, SDL_TEXTUREACCESS_STREAMING, texSize, texSize);
      }

      uint32_t* pixels = NULL;
      int pitch = 0;
      SDL_LockTexture(tex, NULL, (void**) & pixels, &pitch);



      uint16_t patternAddr = ((uint16_t)readTms9918Reg(tms9918, TMS_REG_PATTERN_TABLE) & ((mode == TMS_MODE_GRAPHICS_II) ? 0x04 : 0x07)) << 11;

      uint16_t colorAddr = ((uint16_t)readTms9918Reg(tms9918, TMS_REG_COLOR_TABLE) & ((mode == TMS_MODE_GRAPHICS_II) ? 0x80 : 0xff)) << 6;

      ImVec2 uv0(0.0, 0.0);
      ImVec2 uv1(0.0, 0.0);

      if (mode == TMS_MODE_GRAPHICS_I || mode == TMS_MODE_TEXT)
      {
        for (int i = 0; i < (256 * 8); ++i)
        {
          uint8_t pattByte = readTms9918Vram(tms9918, (patternAddr + i) & 0x3fff);

          uint8_t colByte = readTms9918Reg(tms9918, TMS_REG_FG_BG_COLOR);
          if (mode == TMS_MODE_GRAPHICS_I)
          {
            colByte = readTms9918Vram(tms9918, (colorAddr + i / 64) & 0x3fff);
          }
          uint32_t fg = vrEmuTms9918Palette[colByte >> 4];
          uint32_t bg = vrEmuTms9918Palette[colByte & 0x0f];


          int pixelOffset = ((i & 0x78) >> 3) * 8 + (i & 0x07) * texSize + (i >> 7) * texSize * 8;

          for (int x = 0; x < 8; ++x)
          {
            pixels[pixelOffset++] = (pattByte & 0x80) ? fg : bg;
            pattByte <<= 1;
          }
        }
      }
      else if (mode == TMS_MODE_GRAPHICS_II)
      {
        for (int i = 0; i < (768 * 8); ++i)
        {
          uint8_t pattByte = readTms9918Vram(tms9918, (patternAddr + i) & 0x3fff);
          uint8_t colByte = readTms9918Vram(tms9918, (colorAddr + i) & 0x3fff);
          uint32_t fg = vrEmuTms9918Palette[colByte >> 4];
          uint32_t bg = vrEmuTms9918Palette[colByte & 0x0f];

          int pixelOffset = ((i & 0xf8) >> 3) * 8 + (i & 0x07) * texSize + (i >> 8) * texSize * 8;

          for (int x = 0; x < 8; ++x)
          {
            pixels[pixelOffset++] = (pattByte & 0x80) ? fg : bg;
            pattByte <<= 1;
          }
        }
      }

      SDL_UnlockTexture(tex);

      float size = 1.0f / 32.0f;

      uv1 = ImVec2(size, size);
      uint16_t pattIdx = 0;

      for (int r = 1; r < tableRows; ++r)
      {
        uv0.x = 0.0;
        uv1.x = size;

        ImGui::TableNextRow();
        ImGui::TableSetColumnIndex(0);
        ImGui::Text("%04x", (r - 1) * (tableColumns - 1) * 8);


        for (int c = 1; c < tableColumns; ++c)
        {
          ImGui::TableSetColumnIndex(c);
          ImGui::Image(tex, ImVec2(24, 24), uv0, uv1);
          if (ImGui::IsItemHovered())
          {
            patternTool(pattIdx % 256,  patternAddr + pattIdx * 8, tex, uv0, uv1);
          }

          uv0.x = uv0.x + size;
          uv1.x = uv1.x + size;
          ++pattIdx;
        }

        uv0.y = uv0.y + size;
        uv1.y = uv1.y + size;
      }
      ImGui::PopStyleColor();
      ImGui::EndTable();
      ImGui::PopStyleVar();
    }
    else
    {
      ImGui::Text("TMS9918A not present");
    }
  }
  ImGui::End();
}


void debuggerTmsSpritesView(SDL_Renderer* renderer, bool* show)
{
  static SDL_Texture* tex = NULL;

  ImGui::SetNextWindowContentSize(ImVec2(200, 0));
  if (ImGui::Begin("TMS9918A Sprites", show, ImGuiWindowFlags_HorizontalScrollbar))
  {
    if (tms9918)
    {
      ImGui::BeginTable("SpritesTable", 6, ImGuiTableFlags_SizingFixedFit);
      ImGui::PushStyleColor(ImGuiCol_Text, yellow);

      ImGui::TableSetupColumn("#");
      ImGui::TableSetupColumn("X");
      ImGui::TableSetupColumn("Y");
      ImGui::TableSetupColumn("Idx");
      ImGui::TableSetupColumn("Col");
      ImGui::TableSetupColumn("Pattern");
      ImGui::TableHeadersRow();

      if (tex == NULL)
      {
        tex = SDL_CreateTexture(renderer, SDL_PIXELFORMAT_RGBA8888, SDL_TEXTUREACCESS_STREAMING, 16, 16 * 32);
      }

      uint32_t* pixels = NULL;
      int pitch = 0;
      SDL_LockTexture(tex, NULL, (void**)&pixels, &pitch);
      memset(pixels, 8, 16 * 32 * sizeof(uint32_t));

      uint16_t attrAddr = ((uint16_t)readTms9918Reg(tms9918, TMS_REG_SPRITE_ATTR_TABLE) & 0x7f) << 7;
      uint16_t pattAddr = ((uint16_t)readTms9918Reg(tms9918, TMS_REG_SPRITE_PATT_TABLE) & 0x07) << 11;
      bool sprite16 = readTms9918Reg(tms9918, TMS_REG_1) & 0x02;
      int spriteSizePx = sprite16 ? 16 : 8;

      for (int i = 0; i < 32; ++i)
      {
        uint8_t spriteIndex = readTms9918Vram(tms9918, attrAddr + 2);
        uint32_t spriteColor = vrEmuTms9918Palette[readTms9918Vram(tms9918, attrAddr + 3) & 0x0f];

        uint16_t sprAddr = pattAddr + spriteIndex * 8;

        for (int y = 0; y < spriteSizePx; ++y)
        {
          uint8_t pattByte = readTms9918Vram(tms9918, sprAddr++);

          for (int x = 0; x < 8; ++x)
          {
            pixels[y * 16 + x] = (pattByte & 0x80) ? spriteColor : 0x181818ff;
            pattByte <<= 1;
          }
        }

        if (sprite16)
        {
          for (int y = 0; y < spriteSizePx; ++y)
          {
            uint8_t pattByte = readTms9918Vram(tms9918, sprAddr++);

            for (int x = 0; x < 8; ++x)
            {
              pixels[y * 16 + x + 8] = (pattByte & 0x80) ? spriteColor : 0x181818ff;
              pattByte <<= 1;
            }
          }
        }
        
        pixels += 16 * 16;
        attrAddr += 4;
      }


      SDL_UnlockTexture(tex);

      float sizeX = sprite16 ? 1.0f : 0.5f;
      float sizeY = sizeX / 32.0f;
      float strideY = 1.0f / 32.0f;

      ImVec2 uv0(0.0f, 0.0f);
      ImVec2 uv1(sizeX, 0.0f + sizeY);
      
      attrAddr = ((uint16_t)readTms9918Reg(tms9918, TMS_REG_SPRITE_ATTR_TABLE) & 0x7f) << 7;

      for (int idx = 0; idx < 32; ++idx)
      {
        ImGui::TableNextRow();
        ImGui::TableSetColumnIndex(0);
        ImGui::Text("#%02d", idx);
        ImGui::TableSetColumnIndex(1);
        ImGui::Text("%d", readTms9918Vram(tms9918, attrAddr + 1));
        ImGui::TableSetColumnIndex(2);
        ImGui::Text("%d", readTms9918Vram(tms9918, attrAddr + 0));
        ImGui::TableSetColumnIndex(3);
        ImGui::Text("%d", readTms9918Vram(tms9918, attrAddr + 2));
        ImGui::TableSetColumnIndex(4);
        ImGui::Text("$%02x", readTms9918Vram(tms9918, attrAddr + 3));
        ImGui::TableSetColumnIndex(5);

        ImGui::Image(tex, ImVec2(64, 64), uv0, uv1);

        uv0.y = uv0.y + strideY;
        uv1.y = uv1.y + strideY;
        attrAddr += 4;
      }
      ImGui::PopStyleColor();
      ImGui::EndTable();
    }
    else
    {
      ImGui::Text("TMS9918A not present");
    }
  }
  ImGui::End();
}


void debuggerTmsSpritePatternsView(SDL_Renderer* renderer, bool* show)
{
  static SDL_Texture* tex = NULL;
  vrEmuTms9918Mode mode = (vrEmuTms9918Mode)getTms9918Mode(tms9918);

  bool sprite16 = readTms9918Reg(tms9918, TMS_REG_1) & 0x02;
  int spriteSizePx = sprite16 ? 16 : 8;

  int tableColumns = 17;
  int tableRows = 17;

  ImGui::SetNextWindowContentSize(ImVec2(tableColumns * 26.0f, 0.0f));
  if (ImGui::Begin("TMS9918A Sprite Patterns", show, ImGuiWindowFlags_HorizontalScrollbar))
  {
    if (tms9918)
    {

      ImGui::PushStyleVar(ImGuiStyleVar_CellPadding, ImVec2(1, 1));
      ImGui::BeginTable("PatternsTable", tableColumns, ImGuiTableFlags_SizingFixedFit | ImGuiTableFlags_NoBordersInBody);
      ImGui::PushStyleColor(ImGuiCol_Text, yellow);

      ImGui::TableNextRow();
      ImGui::TableSetColumnIndex(0);
      ImGui::TextUnformatted("$");

      for (int i = 1; i < tableColumns; ++i)
      {
        ImGui::TableSetColumnIndex(i);
        ImGui::Text("$%02x", (i - 1) * 16);
      }


      const int texSize = 128;

      if (tex == NULL)
      {
        tex = SDL_CreateTexture(renderer, SDL_PIXELFORMAT_RGBA8888, SDL_TEXTUREACCESS_STREAMING, texSize, texSize);
      }

      uint32_t* pixels = NULL;
      int pitch = 0;
      SDL_LockTexture(tex, NULL, (void**)&pixels, &pitch);

      uint16_t patternAddr = ((uint16_t)readTms9918Reg(tms9918, TMS_REG_SPRITE_PATT_TABLE) & 0x07) << 11;

      ImVec2 uv0(0.0, 0.0);
      ImVec2 uv1(0.0, 0.0);

      for (int i = 0; i < (256 * 8); ++i)
      {
        uint8_t pattByte = readTms9918Vram(tms9918, (patternAddr + i) & 0x3fff);

        uint32_t fg = 0xffffffff;
        uint32_t bg = 0;

        int pattIndex = (i & 0xf0) >> 4;
        int pattRow = i & 0x07;
        int cellRow = i >> 8;
        int oddOffset = ((i & 0x08) >> 3) * 8 * texSize;

        int pixelOffset = oddOffset + cellRow * 16 * texSize + pattIndex * 8 + pattRow * texSize;
//        int pixelOffset = ((i & 0x78) >> 3) * 8 + (i & 0x07) * texSize + (i >> 7) * texSize * 8;

        for (int x = 0; x < 8; ++x)
        {
          pixels[pixelOffset++] = (pattByte & 0x80) ? fg : bg;
          pattByte <<= 1;
        }
      }

      SDL_UnlockTexture(tex);

      float size = 1.0f / 16.0f;

      uv1 = ImVec2(size, size);
      uint16_t pattIdx = 0;

      for (int r = 1; r < tableRows; ++r)
      {
        uv0.x = 0.0;
        uv1.x = size;
        ImGui::TableNextRow();
        ImGui::TableSetColumnIndex(0);
        if (r & 1)
        {
          ImGui::Text("%04x", (r - 1) * (tableColumns - 1) * 8);
        }


        for (int c = 1; c < tableColumns; ++c)
        {
          ImGui::TableSetColumnIndex(c);
          ImGui::Image(tex, ImVec2(24, 24), uv0, uv1);
          if (ImGui::IsItemHovered())
          {
            patternTool(pattIdx, patternAddr + pattIdx * 8, tex, uv0, uv1);
          }

          uv0.x = uv0.x + size;
          uv1.x = uv1.x + size;
          pattIdx += 2;
        }
        
        pattIdx -= (r & 1) ? 31 : 1;

        uv0.y = uv0.y + size;
        uv1.y = uv1.y + size;
      }
      ImGui::PopStyleColor();
      ImGui::EndTable();
      ImGui::PopStyleVar();
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
  static int regInput = -1;
  static char str0[12] = "$00";

  if (ImGui::Begin("TMS9918A Reg", show, ImGuiWindowFlags_HorizontalScrollbar))
  {
    if (tms9918)
    {
      ImGui::PushStyleColor(ImGuiCol_Text, green);
      std::string desc;
      vrEmuTms9918Mode mode = (vrEmuTms9918Mode)getTms9918Mode(tms9918);

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
            addr = (r & ((mode == TMS_MODE_GRAPHICS_II) ? 0x80 : 0xff)) << 6;
            break;
          case 4:
            desc += "PATT";
            addr = (r & ((mode == TMS_MODE_GRAPHICS_II) ? 0x04 : 0x07)) << 11;
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


        ImGui::PushStyleColor(ImGuiCol_Text, yellow);
        ImGui::Text("R%d", y);
        ImGui::PopStyleColor();
        ImGui::SameLine();
        if (regInput == y)
        {
          if (ImGui::InputText(" ", str0, IM_ARRAYSIZE(str0), ImGuiInputTextFlags_EnterReturnsTrue))
          {
            int val = r;
            SDL_sscanf(str0, "$%x", &val);
            writeTms9918Reg(tms9918, y, (uint8_t)val);
            regInput = -1;
          }
        }
        else
        {
          if (addr == 0xffff)
            ImGui::Text("$%02x %s", r, desc.c_str());
          else
            ImGui::Text("$%02x %s: $%04x ", r, desc.c_str(), addr);
        }

        if (ImGui::IsItemClicked()) {
          regInput = y;
          SDL_snprintf(str0, sizeof(str0), "$%02x", r);
        }
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



void debuggerVia6522View(bool* show)
{
  if (ImGui::Begin("65C22 VIA", show, ImGuiWindowFlags_HorizontalScrollbar))
  {
    if (via)
    {
      ImGui::PushStyleColor(ImGuiCol_Text, green);
      const char *desc = NULL;

      for (uint8_t y = 0; y < 15; ++y)
      {
        switch (y)
        {
          case 0: desc = "PORT B"; break;
          case 1: desc = "PORT A"; break;
          case 2: desc = "DDR B"; break;
          case 3: desc = "DDR A"; break;
          case 4: desc = "T1CL"; break;
          case 5: desc = "T1CH"; break;
          case 6: desc = "T1LL"; break;
          case 7: desc = "T1LH"; break;
          case 8: desc = "T2CL"; break;
          case 9: desc = "T2CH"; break;
          case 10: desc = "SR"; break;
          case 11: desc = "ACR"; break;
          case 12: desc = "PCR"; break;
          case 13: desc = "IFR"; break;
          case 14: desc = "IER"; break;
        }

        uint8_t r = readVia6522Reg(via, y);

        ImGui::PushStyleColor(ImGuiCol_Text, yellow);
        ImGui::Text("R%02d", y);
        ImGui::PopStyleColor();
        ImGui::SameLine();
        ImGui::Text("%-6s: $%02x %d", desc, r, r);
      }

      ImGui::PopStyleColor();

    }
    else
    {
      ImGui::Text("VIA not present");
    }
  }
  ImGui::End();
}
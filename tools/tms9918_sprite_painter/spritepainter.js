var state = {
  NONE: 0,
  PAINT: 1,
  ERASE: 2,
  mode: this.NONE,
  isPainting() {
    return(this.mode === 1)
  },
  isErasing() {
    return(this.mode === 2)
  },
}

function turnOn(td) {
  td.removeClass("off")
  td.addClass("on")
}

function turnOff(td) {
  td.removeClass("on")
  td.addClass("off")
}

function buildHex(quadrant) {
  let t = $("#" + quadrant + " tbody")
  let i = 0
  let hex = ""
  for (const r of t.children()) {
    let val = 0
    let j = 0
    for(const c of $(r).children()) {
      if($(c).hasClass("on")) {
        val += 1 << (7 - j)
      }
      j += 1
    }
    let rHex = val.toString(16).padStart(2, "0")
	if (hex.length > 0) hex += ","
    hex = hex.concat("$"+rHex)
    val = 0
    i += 1
  }
  let sel = "#code_" + quadrant
  $(sel).val(hex)
}

function refresh() {
  $("#codeAll").val(
    "!byte " + $("#code_tl").val() + "\n" +
    "!byte " + $("#code_bl").val() + "\n" +
    "!byte " + $("#code_tr").val() + "\n" +
    "!byte " + $("#code_br").val()
  )
}

function writeQuadrants() {
  buildHex("tl")
  buildHex("tr")
  buildHex("bl")
  buildHex("br")
  refresh()
}

function loadQuadrants() {
  loadHex("tl")
  loadHex("tr")
  loadHex("bl")
  loadHex("br")
  writeQuadrants()
}
function loadHex(quadrant) {
	loadHexTranform(quadrant, quadrant, false, false)
}

function loadHexTranform(fromQuad, toQuad, flipH, flipV) {
  let t = $("#" + toQuad + " tbody")
  let i = 0
  let rows = t.children()
  if (flipV) rows = rows.get().reverse()
  for (const r of rows) {
    let j = 0
    let idx = i * 4 + j + 1
    let row = parseInt($("#code_" + fromQuad).val().slice(idx, idx + 2), 16)
	let cols = $(r).children()
	if (flipH) cols = cols.get().reverse()
    for(const c of cols) {
      bit = row & (1 << (7 - j))
      if(bit > 0){
        turnOn($(c))
      } else {
        turnOff($(c))
      }
      j += 1
    }
    i += 1
  }
}

function updateColors(quad, values) {
  let t = $("#" + quad + " tbody")
  let rows = t.children()
  let i = 0
  for (const r of rows) {
      let idx = i * 4 + 1
      let row = values.slice(idx, idx + 2)
	  $(r).removeClass()
	  $(r).addClass("f0"+ row[0])
	  $(r).addClass("b0"+ row[1])
      i += 1
  }	
}


function flipH() {
  loadHexTranform("tl", "tr", true, false)
  loadHexTranform("tr", "tl", true, false)
  loadHexTranform("bl", "br", true, false)
  loadHexTranform("br", "bl", true, false)
  writeQuadrants()
}

function flipV() {
  loadHexTranform("tl", "bl", false, true)
  loadHexTranform("bl", "tl", false, true)
  loadHexTranform("br", "tr", false, true)
  loadHexTranform("tr", "br", false, true)
  writeQuadrants()
}

function allOff() {
  let t = $(".pixels tbody")
  for (const r of t.children()) {
    for(const c of $(r).children()) {
      turnOff($(c))
      $(c).html("")
    }
  }
}

function modePaint(e) {
  if(e.which != 1) {
    return
  }
  if(state.isPainting()) {
    turnOn($(this))
  } else if(state.isErasing()) {
    turnOff($(this))
  }
  writeQuadrants()
}

function fill() {
  $("#code_tl").val("$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff")
  $("#code_bl").val("$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff")
  $("#code_tr").val("$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff")
  $("#code_br").val("$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff")
  loadQuadrants()
}

function clear() {
  $("#code_tl").val("$00,$00,$00,$00,$00,$00,$00,$00")
  $("#code_bl").val("$00,$00,$00,$00,$00,$00,$00,$00")
  $("#code_tr").val("$00,$00,$00,$00,$00,$00,$00,$00")
  $("#code_br").val("$00,$00,$00,$00,$00,$00,$00,$00")
  loadQuadrants()
}

function copy() {
  $("#codeAll").select()
  document.execCommand('copy')
}

function onPaste() {
 setTimeout(updateFromCombined, 100)
}

function onPastePal() {
 setTimeout(updateFromPalCombined, 100)
}

function updateFromCombined() {
 var rows=$("#codeAll").val().split("\n")
 if (rows.length >= 4)
   $("#code_tl").val(rows[0].substr(6,31))
   $("#code_bl").val(rows[1].substr(6,31))
   $("#code_tr").val(rows[2].substr(6,31))
   $("#code_br").val(rows[3].substr(6,31))
   loadQuadrants()
}

function updateFromPalCombined() {
 var rows=$("#paletteAll").val().split("\n")
 if (rows.length >= 4)
   updateColors("tl", rows[0].substr(6,31))
   updateColors("bl", rows[1].substr(6,31))
   updateColors("tr", rows[2].substr(6,31))
   updateColors("br", rows[3].substr(6,31))
}

function bindButtons() {
  $("#buildHex").click(writeQuadrants)
  $("#loadHex").click(loadQuadrants)
  $("#flipH").click(flipH)
  $("#flipV").click(flipV)
  $("#fill").click(fill)
  $("#copy").click(copy)
  $("#codeAll").on("paste", onPaste)
  $("#paletteAll").on("paste", onPastePal)
  $("body").on('dragover', false) 
	       .on('drop', function (e) {
    let dt = e.originalEvent.dataTransfer
	$("#codeAll").val(dt.getData("text"))
	updateFromCombined()
  });
}

function noop() { return false }

function unbindPaint() {
  $(".pixels td").off("mouseenter")
  $(".pixels td").off("mousedown")
  $(".pixels").off("contextmenu")
}

function bindPaint() {
  $("#palette").mouseleave(stopDrag)
  $(".pixels").contextmenu(noop)
  $(".pixels td").mousedown(startDrag)
  $(".pixels td").mouseup(stopDrag)
  $(".pixels td").mouseenter(modePaint)
}

function startDrag(e) {
  if($(this).hasClass("on")) {
    state.mode = state.ERASE
    turnOff($(this))
  } else {
    state.mode = state.PAINT
    turnOn($(this))
  }
  e.preventDefault()
}

function stopDrag(e) {
  state.mode = state.NONE
  e.preventDefault()
}

$(document).ready(function() {
  bindPaint()
  bindButtons()
  $("#code_tl, #code_tr, #code_bl, #code_br").change(loadQuadrants)
  allOff()
  writeQuadrants()
});

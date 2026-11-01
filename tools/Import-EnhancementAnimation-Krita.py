"""Run inside Krita's Scripter, not standalone Python. No AI image generation."""
from pathlib import Path
from krita import Krita

folder = Path(r"D:\kirta project WoW Forever\Enhancement-animation-v4")
frames = sorted(folder.glob("enhancement_*.png"))
if len(frames) != 36:
    raise RuntimeError("Expected 36 PNG frames in " + str(folder))
output = folder.parent / "Enhancement-thunder-lightning-animated-v4.kra"
if output.exists():
    raise RuntimeError("Project already exists; choose a new output filename before running again.")
app = Krita.instance()
doc = app.createDocument(1024, 1024, "Enhancement / thunder, lightning and sundering", "RGBA", "U8", "", 72.0)
if not doc:
    raise RuntimeError("Krita could not create the animation document.")
layer = doc.createNode("Enhancement / animated effect", "paintlayer")
doc.rootNode().addChildNode(layer, None)
doc.setActiveNode(layer)
window = app.activeWindow()
if not window:
    raise RuntimeError("Open a Krita window before running this importer.")
window.addView(doc)
if not doc.importAnimation([str(frame) for frame in frames], 0, 1):
    raise RuntimeError("Krita could not import the animation frames.")
doc.waitForDone()
doc.setFramesPerSecond(12)
doc.setFullClipRangeStartTime(0)
doc.setFullClipRangeEndTime(35)
doc.setPlayBackRange(0, 35)
doc.setCurrentTime(0)
doc.refreshProjection()
doc.waitForDone()
if not doc.saveAs(str(output)):
    raise RuntimeError("Krita could not save " + str(output))
print("Saved playable Krita animation: " + str(output))

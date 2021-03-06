# Torus-Music-Generation

Made in SuperCollider 3.11.0 and Processing 3.5.4

## Instructions

Installations of SuperCollider and Processing are needed.<br>
You can find the downloads for your operating system here:<br>
https://supercollider.github.io/download | https://processing.org/download/<br>
Additionally you will need to install the extension oscP5, which can be done inside Processing.<br>
Go to "Sketch" -> "Import Library" -> "Add Library", search for "oscP5" and install it.<br>
The SuperCollider Quark wslib is also necessary. In SuperCollider open a new file, type 'Quarks.install("wslib")'<br>
and execute that line by pressing shift+enter.<br><br>

Once installed, open the provided files. The ".scd" is for SuperCollider and the "main.pde" is the main Processing file.<br>
The other two ".pde" files are self written classes that need to be in the same folder as "main.pde".<br>
That folder has to also be named "main" so that processing knows the files' relation.<br>
In SuperCollider you will find two blocks of code, outlined by parantheses.<br>
To execute these, you need to place the cursor inside and press ctrl+enter, or cmd+enter on Mac.<br>
First execute "s.boot;", or press ctrl+b, or cmd+b to boot the scsynth for sound synthesis.<br>
If you don't start scsynth, an error will occur as soon as SuperCollider tries to play something from the server.<br>
When the server is running (indicated by the green numbers at the bottom right) you can execute the second<br>
code block, which then waits for the Processing sketch to start.<br>
After this, go to Processing and hit ctrl+r, or cmd+r. The Sketch should come up and the sound patterns should start playing.<br><br>

Have fun!

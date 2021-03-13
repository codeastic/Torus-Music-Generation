# Torus-Music-Generation

Made in SuperCollider 3.11.0 and Processing 3.5.4

## Instructions

Installations of SuperCollider and Processing are needed.
You can find the downloads for your operating system here:
https://supercollider.github.io/download
https://processing.org/download/
Additionally you will need to install the extension oscP5 which can be done inside Processing.
Go to "Sketch" -> "Import Library" -> "Add Library", search for "oscP5" and install it.

Once installed, open the provided files. The .scd is for SuperCollider and the main.pde is the main Processing file.
The other two .pde files are self written classes that should appear next to the main tab. If not, open all three.
In SuperCollider you will find two blocks of code. First the s.boot; to boot the scsynth for sound synthesis.
If you don't start scsynth, an error will occur as soon as SuperCollider tries to play something from the server.
When the server is running (indicated by the green numbers at the bottom right) you can execute the second
code block (by pressing ctrl+enter or cmd+enter on a Mac) which then waits for the Processing sketch to start.
After this go to Processing and hit ctrl+r or cmd+r. The Sketch should come up and the sound patterns should start playing.

Have fun!

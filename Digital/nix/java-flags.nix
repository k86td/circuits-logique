# JVM flags shared by the packaged wrapper and the dev-shell launcher.
[
  # Digital was built against JDK 11. XStream 1.4.20 reflects into java.base
  # collections when loading/saving .dig files; on JDK 16+ the module system
  # denies that by default and the load fails with InaccessibleObjectException.
  "--add-opens=java.base/java.util=ALL-UNNAMED"
  "--add-opens=java.base/java.lang=ALL-UNNAMED"
  "--add-opens=java.base/java.lang.reflect=ALL-UNNAMED"
  "--add-opens=java.base/java.text=ALL-UNNAMED"
  "--add-opens=java.desktop/java.awt.font=ALL-UNNAMED"

  # Readable text on the circuit canvas.
  "-Dawt.useSystemAAFontSettings=on"
  "-Dswing.aatext=true"
]

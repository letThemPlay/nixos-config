#
# What each role opens by default. A role in use with an entry here becomes the
# default handler for these types when ltp.apps.defaultHandlers is on.
#
_: {

  browser = [
    "x-scheme-handler/http"
    "x-scheme-handler/https"
    "text/html"
    "application/xhtml+xml"
  ];

  fileManager = [ "inode/directory" ];

  editor = [
    "text/plain"
    "text/markdown"
    "text/x-shellscript"
    "text/x-python"
    "text/x-csrc"
    "text/x-nix"
    "application/json"
    "application/toml"
    "application/x-yaml"
  ];

  imageViewer = [
    "image/png"
    "image/jpeg"
    "image/gif"
    "image/webp"
    "image/bmp"
    "image/tiff"
    "image/avif"
    "image/svg+xml"
  ];

  pdfViewer = [
    "application/pdf"
    "application/epub+zip"
  ];

  mediaPlayer = [
    "video/mp4"
    "video/webm"
    "video/x-matroska"
    "video/mpeg"
    "video/quicktime"
    "video/x-msvideo"
    "audio/mpeg"
    "audio/flac"
    "audio/ogg"
    "audio/wav"
    "audio/mp4"
    "audio/x-opus+ogg"
  ];

}

"""A web server for a guitar page."""

from http.server import BaseHTTPRequestHandler, HTTPServer
from guitar import make_strings, make_song
import json

# The beginning of the output HTML
prefix = """
<html>
<head>

<script type="text/javascript"
  src="https://ajax.googleapis.com/ajax/libs/jquery/1.7.2/jquery.min.js">
</script>

<script type="text/javascript">

var strings = """

# Middle of the output HTML
middle = """;
var song = """

# The end of the output HTML
suffix = """;

function init() {

  var sample_rate = 44100;
  var channels = 1;
  var volume = 0.1;
  var keys = {}
  var audio = new Audio();
  audio.volume = volume;
  audio.mozSetup(channels, sample_rate);

  $.each(strings, function(j, tuple) {
    var key = tuple[0];
    var msg = tuple[1];
    var keyCode = key.toUpperCase().charCodeAt(0);
    keys[keyCode] = tuple;
    $(".content").append('<div>' + key + ': ' + msg + '</div>');
  });

  function playKey(keyCode) {
    note_samples = keys[keyCode][2];
    note_samples = scale(note_samples);
    audio.mozWriteAudio(note_samples);
  }

  $(document).keydown(function(evt) {
    if (evt.which in keys) {
      playKey(evt.which)
	}
  });

  function scale(samples) {
    return new Float32Array(samples.map(function(x) { return x/256.0; }));
  }

  $('#song').click(function(){
    loop();
  });

  var i = 0;
  function loop() {
	  if (i < song.length) {
	    audio.mozWriteAudio(scale(song[i]));
	    window.setTimeout(loop, 1000);
	    i = i + 1;
	  } else {
	    i = 0;
	  }
  }
}

var context;
window.addEventListener('load', init, false);
</script>

</head>

<body>
  <div class="content"></div>
  <button id="song">Play Song</button>
</body>

</html>
"""

class Handler(BaseHTTPRequestHandler):
    """An HTTP handler that serves the guitar page."""

    def do_GET(self):
        self.send_response(200)
        self.send_header('Content-type', 'text')
        self.end_headers()

        if self.path == '/':
            data = json.dumps(make_strings(), )
            song = json.dumps(make_song(), )
            self.wfile.write(prefix.encode('utf8'))
            self.wfile.write(data.encode('utf8'))
            self.wfile.write(middle.encode('utf8'))
            self.wfile.write(song.encode('utf8'))
            self.wfile.write(suffix.encode('utf8'))
        else:
            self.wfile.write(''.encode('utf8'))

port = 8000
print('Navigate to http://localhost:{0}/'.format(port))
server = HTTPServer(('', port), Handler)
server.serve_forever()

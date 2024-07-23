extends Control

# AudioStreamPlayer can either be AudioStreamOpusChunked or AudioStreamGeneratorPlayback
var audiostreamopuschunked # : AudioStreamOpusChunked
var audiostreamgeneratorplayback : AudioStreamGeneratorPlayback
var opuspacketsbuffer = [ ]
var audiopacketsbuffer = [ ]

var opusframesize : int = 960
var audiosamplesize : int = 960
var opussamplerate : int = 48000
var audiosamplerate : int = 44100

func _ready():
	var audiostream = $AudioStreamPlayer.stream
	if audiostream == null:
		if ClassDB.can_instantiate("AudioStreamOpusChunked"):
			print("Instantiating AudioStreamOpusChunked")
			audiostream = ClassDB.instantiate("AudioStreamOpusChunked")
		else:
			print("Instantiating AudioStreamGenerator")
			audiostream = AudioStreamGenerator.new()
		$AudioStreamPlayer.stream = audiostream
	else:
		assert (audiostream.resource_local_to_scene)

	$AudioStreamPlayer.play()
	if audiostream.is_class("AudioStreamOpusChunked"):
		audiostreamopuschunked = audiostream
		#var audiostreamopyschunkedplayback = $AudioStreamPlayer.get_stream_playback()
		#audiostreamopyschunkedplayback.begin_resample()
	elif audiostream.is_class("AudioStreamGenerator"):
		if ClassDB.can_instantiate("AudioStreamOpusChunked"):
			audiostreamopuschunked = ClassDB.instantiate("AudioStreamOpusChunked").new()
		audiostreamgeneratorplayback = $AudioStreamPlayer.get_stream_playback()
	else:
		printerr("Incorrect AudioStream type ", audiostream)

func setname(lname):
	set_name(lname)
	$Label.text = name

func processheaderpacket(h):
	print(h["audiosamplesize"],  "  ss  ", h["opusframesize"])
	#h["audiosamplesize"] = 400; h["audiosamplerate"] = 40000
	#print("setting audiosamplesize wrong on receive ", h)
	if opusframesize != h["opusframesize"] or audiosamplesize != h["audiosamplesize"]:
		opusframesize = h["opusframesize"]
		audiosamplesize = h["audiosamplesize"]
		opussamplerate = h["opussamplerate"]
		audiosamplerate = h["audiosamplerate"]
		if audiostreamopuschunked != null:
			audiostreamopuschunked.opusframesize = opusframesize
			audiostreamopuschunked.audiosamplesize = audiosamplesize
			audiostreamopuschunked.opussamplerate = opussamplerate
			audiostreamopuschunked.audiosamplerate = audiosamplerate

			if opusframesize != 0:
				print("createdecoder ", opussamplerate, " ", opusframesize, " ", audiosamplerate, " ", audiosamplesize)
			#$AudioStreamPlayer.play()
	if opusframesize != 0 and audiostreamopuschunked == null:
		print("Compressed opus stream received that we cannot decompress")
				
			

func receivemqttmessage(msg):
	if msg[0] == "{".to_ascii_buffer()[0]:
		var h = JSON.parse_string(msg.get_string_from_ascii())
		if h != null:
			print("audio json packet ", h)
			if h.has("opusframesize"):
				processheaderpacket(h)
	else:
		if opusframesize != 0:
			opuspacketsbuffer.push_back(msg)
		else:
			audiopacketsbuffer.push_back(bytes_to_var(msg))


func _process(_delta):
	$Node/ColorRect2.visible = (len(audiopacketsbuffer) + len(opuspacketsbuffer) > 0)
	if audiostreamgeneratorplayback == null:
		while audiostreamopuschunked.chunk_space_available():
			if len(audiopacketsbuffer) != 0:
				audiostreamopuschunked.push_audio_chunk(audiopacketsbuffer.pop_front())
			elif len(opuspacketsbuffer) != 0:
				audiostreamopuschunked.push_opus_packet(opuspacketsbuffer.pop_front(), 0, 0)
			else:
				break
		$Node/ColorRect.size.x = audiostreamopuschunked.queue_length_frames()/(50.0*881)*$Node/ColorRect2.size.x

	else:
		while audiostreamgeneratorplayback.get_frames_available() > audiosamplesize:
			if len(audiopacketsbuffer) != 0:
				audiostreamgeneratorplayback.push_buffer(audiopacketsbuffer.pop_front())
			elif len(opuspacketsbuffer) != 0:
				var audiochunk = audiostreamopuschunked.opus_packet_to_chunk(opuspacketsbuffer.pop_front(), 0, 0)
				audiostreamgeneratorplayback.push_buffer(audiochunk)
			else:
				break

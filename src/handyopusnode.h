#ifndef HANDYOPUSNODE_H
#define HANDYOPUSNODE_H

#include <godot_cpp/classes/node.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

#include "opus.h"
#include "speex_resampler/speex_resampler.h"

namespace godot {

class HandyOpusNode : public Node {
	GDCLASS(HandyOpusNode, Node)

    // Constants
    const int GODOT_SAMPLE_RATE = 44100;
    const int OPUS_FRAME_SIZE = 480;
    const int OPUS_SAMPLE_RATE = 48000;
    const int CHANNELS = 2;
    const int RESAMPLING_QUALITY = 10; // 0 to 10
    const int DEFAULT_BITRATE = 24000; // bits / second from 500 to 512000
    const int EXPECTED_PACKET_LOSS = 5; // percentage from 0 to 100


protected:
    static void _bind_methods();

private:
    double time_passed;
    int last_opus_error = 0;
    int last_resampler_error = 0;
    OpusDecoder* opus_decoder;
    SpeexResamplerState* resampler;
    PackedVector2Array sample_buf;

    OpusEncoder* opusencoder;
    OpusDecoder* opusdecoder;
    SpeexResamplerState* speexresampler;
    int opussamplerate;
    int opusframesize;
    int audiosamplerate;
    int audiosamplesize;
    float Dtimeframeopus;
    float Dtimeframeaudio;
    PackedVector2Array opusframebuffer;
    PackedByteArray bytepacketbuffer;
    void destroyallsamplers(); 


public:
    PackedVector2Array decode_opus_packet(const PackedByteArray&);

    int createencoder(int opussamplerate, int opusframesize, int audiosamplerate, int audiosamplesize);
    PackedByteArray encodeopuspacket(PackedVector2Array audiosamples); 

    HandyOpusNode();
    ~HandyOpusNode();

};





}

#endif // HANDYOPUSNODE_H

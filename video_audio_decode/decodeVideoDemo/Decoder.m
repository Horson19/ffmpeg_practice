//
//  Decoder.m
//  decodeVideoDemo
//
//  Created by HorsonChan on 2019/8/16.
//  Copyright © 2019 Horson. All rights reserved.
//

#import "Decoder.h"
//核心库 音视频编解码库
#import <libavcodec/avcodec.h>
//导入封装格式库
#import <libavformat/avformat.h>
//工具库
#import <libavutil/imgutils.h>
//视频像素数据格式库
#import <libswscale/swscale.h>


//音频采样格式库
#import <libswresample/swresample.h>

@implementation Decoder

+(void)ffmpegOpenFile:(NSString *)filePath outFile:(NSString *)outFilePath{
    //1.注册
    av_register_all();
    //2.打开输入文件
    AVFormatContext *avformat_context = avformat_alloc_context();
    const char *url = [filePath UTF8String];
    int open_input_result = avformat_open_input(&avformat_context, url, NULL, NULL);
    if (open_input_result != 0) {
        char *error_info = NULL;
        av_strerror(open_input_result, error_info, 1024);
        NSLog(@"打开文件失败 %s",error_info);
        return;
    }
    NSLog(@"打开文件成功");
    
    //3.查找文件流
    int avformat_find_stream_info_reuslt = avformat_find_stream_info(avformat_context, NULL);
    if (avformat_find_stream_info_reuslt < 0) {
        NSLog(@"查找文件流失败");
        return;
    }
    NSLog(@"查找文件流成功");
    
    //4.查找视频流索引位置
    int av_steam_index = -1;
    for (int i = 0; i < avformat_context->nb_streams; i++) {
        if (avformat_context->streams[i]->codecpar->codec_type == AVMEDIA_TYPE_VIDEO) {
            av_steam_index = i;
            break;
        }
    }
    
    //5.获取编解码参数
    //编解码参数会在avformat_find_stream_info()后被填充，这时候直接去取
    AVCodecParameters *codecParams = avformat_context->streams[av_steam_index]->codecpar;
    //6.根据解码器ID来查找解码器
    AVCodec *avdecoder = avcodec_find_decoder(codecParams->codec_id);
    //7.创建解码器上下文
    AVCodecContext *decovder_context = avcodec_alloc_context3(avdecoder);
    //8.填充解码器上下文
    avcodec_parameters_to_context(decovder_context, codecParams);
    //9.打开解码器
    int open_decoderReulst = avcodec_open2(decovder_context, avdecoder, NULL);
    if (open_decoderReulst < 0 ) {
        char *errorDes = NULL;
        av_strerror(open_decoderReulst, errorDes, 1024);
        NSLog(@"打开解码器失败 原因： %s",errorDes);
        return;
    }
    NSLog(@"打开解码器成功 %s ",avdecoder->name);
    
    //11.创建一个packet用来存放读取到的帧数data
    AVPacket *packet = (AVPacket *)av_malloc(sizeof(AVPacket));
    //13.创建一个接收解码好的帧的临时frame buffer
    AVFrame *avframe_in = av_frame_alloc();
    //14.因为帧数会很多，每次都要创建一个临时变量int来接收解析结果，很费内存
    int avcodec_receive_frame_in = 0;
    //15.用一个变量来记录当前第多少帧
    int currentFrameCount = 0;
    //16.准备一个接收原始帧，准备转换为目标帧的context(可以设置转换帧的参数)
    struct SwsContext *swsContext = sws_getContext(decovder_context->width,
                                                   decovder_context->height,
                                                   decovder_context->pix_fmt,
                                                   decovder_context->width,
                                                   decovder_context->height,
                                                   AV_PIX_FMT_YUV420P,
                                                   SWS_FAST_BILINEAR,
                                                   NULL,
                                                   NULL,
                                                   NULL);
    //17.创建一个AVFrame来接收转换为YUV420P像素类型的帧
    AVFrame *avframe_yuv420p = av_frame_alloc();
    //18.开辟一块缓存区缓存得到的一帧yuv数据
    int buffer_size = av_image_get_buffer_size(AV_PIX_FMT_YUV420P,
                             decovder_context->width,
                             decovder_context->height,
                             1);
    uint8_t *out_buffer = (uint8_t *)av_malloc(buffer_size);
    av_image_fill_arrays(avframe_yuv420p->data,
                         avframe_yuv420p->linesize,
                         out_buffer,
                         AV_PIX_FMT_YUV420P,
                         decovder_context->width,
                         decovder_context->height,
                         1);
    int y_size, u_size, v_size;
    //19.打开要写入的文件
    const char *outFile = [outFilePath UTF8String];
    FILE *file_yuv420p = fopen(outFile, "wb");
    if (file_yuv420p == NULL) {
        NSLog(@"输出文件打开失败");
        return;
    }
    
    NSLog(@"输出文件打开成功");
    
    //10.循环读取context中的帧数据
    while (av_read_frame(avformat_context, packet) >= 0) {
        if (packet->stream_index == av_steam_index) {
            //11.发送packet给解码上下文,解码上下文会影响解码结果
            avcodec_send_packet(decovder_context, packet);
            //12.返回解码器解码好了的一帧
            avcodec_receive_frame_in = avcodec_receive_frame(decovder_context, avframe_in);
            if (avcodec_receive_frame_in == 0) {
                NSLog(@"解码一帧成功,%d帧", currentFrameCount);
                //17.转换解码像素格式的frame为yuv420p像素格式的frame
                sws_scale(swsContext,
                          (const uint8_t *const *)avframe_in->data,
                          avframe_in->linesize,
                          0,
                          decovder_context->height,
                          avframe_yuv420p->data,
                          avframe_yuv420p->linesize);
                
                //20.计算大小
                //每个像素点都有y
                y_size = decovder_context->width * decovder_context->height;
                //4：2：0代表总体抽样率  y:u:v = 4:1:1
                //每一行都会有u或v（只会出现u或v）与y的比是4:2，所以总体是4:1:1
                u_size = y_size/4;
                v_size = y_size/4;
                
                //21.写入yuv文件
                //必须按YUV的顺序
                fwrite(avframe_yuv420p->data[0], 1, y_size, file_yuv420p);
                fwrite(avframe_yuv420p->data[1], 1, u_size, file_yuv420p);
                fwrite(avframe_yuv420p->data[2], 1, v_size, file_yuv420p);
            } else {
                NSLog(@"解码一帧失败,%d帧", currentFrameCount);
            }
            currentFrameCount++;
        }
    }
    //22.释放内存，关闭解码器
    av_packet_free(&packet);
    fclose(file_yuv420p);
    av_frame_free(&avframe_in);
    av_frame_free(&avframe_yuv420p);
    free(out_buffer);
    avcodec_close(decovder_context);
    avformat_free_context(avformat_context);
    
    
    //大部分重用变量写在外面是因为for中循环读取帧会非常非常多，省去重复创建对象的资源消耗和内存占用
}

+ (void)decodeAudioOpenFile:(NSString *)filePath outFile:(NSString *)outFilePath{
    av_register_all();
    const char *url = [filePath UTF8String];
    AVFormatContext *avformat_context = avformat_alloc_context();
    int avformat_open_input_result = avformat_open_input(&avformat_context, url, NULL, NULL);
    if (avformat_open_input_result != 0) {
        NSLog(@"打开输入流文件失败");
        return;
    }
    
    int avSteam_audio_index = 0;
    for (int i = 0 ; i < avformat_context->nb_streams; i++) {
        if (avformat_context->streams[i]->codecpar->codec_type == AVMEDIA_TYPE_AUDIO) {
            avSteam_audio_index = i;
        }
    }
    
    AVCodecParameters *codecParams = avformat_context->streams[avSteam_audio_index]->codecpar;
    AVCodec *decoder = avcodec_find_decoder(codecParams->codec_id);
    if (decoder == NULL) {
        NSLog(@"查找音频解码器失败");
        return;
    }
    
    AVCodecContext *avcodec_context = avcodec_alloc_context3(decoder);
    avcodec_parameters_to_context(avcodec_context, codecParams);
    int avcodec_open2_reuslt = avcodec_open2(avcodec_context, decoder, NULL);
    if (avcodec_open2_reuslt != 0) {
        NSLog(@"initianlize audio decoder failed");
        return;
    }
    int audioFramesCount = 0;
    AVFrame *avframe_in = av_frame_alloc();
    int audio_decode_result = 0;
    
    //音频转换上下文
    SwrContext *swr_context = swr_alloc();
    
    //设置参数
    //channel layout  通道数，单声道，双声道
    //output sample format 采样精度，采样单位大小，比如16位，就是以2字节为一个单位大小，就是精度
    //sample rate 采样率 一般44100Hz
    //log_offset log日志偏移量（从哪里开始统计）
    //log_ctx log上下文context
    
    //获取原本codecParams内数据
    //卧槽 也可以直接用channels->channels_layout
    int64_t in_ch_layout = av_get_default_channel_layout(avcodec_context->channels);
    enum AVSampleFormat in_sample_fmt = avcodec_context->sample_fmt;
    int in_sample_rate = avcodec_context->sample_rate;
    
    //可自定义,也可保持一致
    int64_t out_ch_layout = AV_CH_LAYOUT_STEREO;
    enum AVSampleFormat out_sample_fmt = AV_SAMPLE_FMT_S16;
    int out_sample_rate = avcodec_context->sample_rate;
    int log_offset = 0;
    
    swr_alloc_set_opts(swr_context,
                       out_ch_layout,
                       out_sample_fmt,
                       out_sample_rate,
                       in_ch_layout,
                       in_sample_fmt,
                       in_sample_rate,
                       log_offset,
                       NULL);
    //初始化音频转换上下文
    swr_init(swr_context);
    
    //每个声道数据大小 采样率 * 采样精度
    int buffer_size_per_channel = out_sample_rate * 2;
    //缓冲区大小 = 每个声道数据大小  * 声道数
    //但是下文的convert中说明是amount of space available for output in samples per channel
    //不知道这个out_buffer是不是倒地需要乘以通道数
    uint8_t *out_buffer = (uint8_t *)av_malloc( buffer_size_per_channel * 2 );
    
    //打开文件
    const char * outUrl = [outFilePath UTF8String];
    FILE *out_file_pcm = fopen(outUrl, "wb");
    if (out_file_pcm == NULL) {
        NSLog(@"打开音频输出文件失败");
        return;
    }
    //packet 是一帧压缩数据
    AVPacket *packet = (AVPacket *)av_malloc(sizeof(AVPacket));
    while (av_read_frame(avformat_context, packet) >= 0) {
        if (packet->stream_index == avSteam_audio_index) {
            avcodec_send_packet(avcodec_context, packet);
            audio_decode_result = avcodec_receive_frame(avcodec_context, avframe_in);
            if (audio_decode_result == 0) {
                NSLog(@"音频采样成功 第%d帧",audioFramesCount);
                //3.类型转换 将解码帧转换为pcm的采样格式(MP3 AAC等都是压缩格式)
                swr_convert(swr_context,
                            &out_buffer,
                            buffer_size_per_channel,
                            (const uint8_t **)avframe_in->data,
                            avframe_in->nb_samples);
                //写入文件
                fwrite(out_buffer, 1, buffer_size_per_channel * 2, out_file_pcm);
            } else {
                NSLog(@"失败 第%d帧",audioFramesCount);
            }
            audioFramesCount++;
        }
    }
    
    //释放内存
    fclose(out_file_pcm);
    av_packet_free(&packet);
    swr_free(&swr_context);
    av_free(out_buffer);
    av_frame_free(&avframe_in);
    avcodec_free_context(&avcodec_context);
    avformat_close_input(&avformat_context);
    
}
@end

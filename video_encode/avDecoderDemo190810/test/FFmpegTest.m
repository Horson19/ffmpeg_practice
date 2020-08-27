//
//  FFmpegTest.m
//  avDecoderDemo190810
//
//  Created by HorsonChan on 2019/8/10.
//  Copyright © 2019 Horson. All rights reserved.
//

#import "FFmpegTest.h"
//核心库 音视频编解码库
#import <libavcodec/avcodec.h>
//导入封装格式库
#import <libavformat/avformat.h>
//工具库
#import <libavutil/imgutils.h>
//视频像素数据格式库
#import <libswscale/swscale.h>

//todo: xh264还没有被编译到库中


int flush_encoder(AVFormatContext *fmt_ctx, unsigned int stream_index) {
    int ret;
    int got_frame;
    AVPacket enc_pkt;
    if (!(fmt_ctx->streams[stream_index]->codec->codec->capabilities &
          CODEC_CAP_DELAY))
        return 0;
    while (1) {
        enc_pkt.data = NULL;
        enc_pkt.size = 0;
        av_init_packet(&enc_pkt);
        ret = avcodec_encode_video2(fmt_ctx->streams[stream_index]->codec, &enc_pkt,
                                    NULL, &got_frame);
        av_frame_free(NULL);
        if (ret < 0)
            break;
        if (!got_frame) {
            ret = 0;
            break;
        }
        NSLog(@"Flush Encoder: Succeed to encode 1 frame!\tsize:%5d\n", enc_pkt.size);
        /* mux encoded frame */
        ret = av_write_frame(fmt_ctx, &enc_pkt);
        if (ret < 0)
            break;
    }
    return ret;
}

@implementation FFmpegTest

+(void)ffmpegEncodeFile:(NSString *)filePath outFilePath:(NSString *)outFilePath{
    av_register_all();
    AVFormatContext *avformat_context = avformat_alloc_context();
    const char *outFileUrl = [outFilePath UTF8String];
    //根据params猜测输出封装格式
    AVOutputFormat *output_format = av_guess_format(NULL, outFileUrl, NULL);
    //指定封装类型
    avformat_context->oformat = output_format;
    //第三步：打开输入文件
    //1.输出流
    //2.输出文件路径
    //3.权限——>输出到文件中
    if (avio_open(&avformat_context->pb, outFileUrl, AVIO_FLAG_WRITE) < 0) {
        NSLog(@"打开输出文件失败");
        return;
    }
    
    //第四步：创建输出码流->创建了一块内存空间->并不知道是什么类型流->希望是视频流
    AVStream *av_video_steam = avformat_new_stream(avformat_context, NULL);
    
    //第五步：查找视频编码器
    //1、获取编解码器上下文
    AVCodecContext *avcodec_context = av_video_steam->codec;
    
    //2、设置编解码器上下文参数
    //目标：设置为是一个视频编码器上下文->指定的是视频编码器
    //上下文种类：视频解码器类型、视频编码器类型、音频解码器类型、音频编码器类型
    //2.1 设置视频编码器ID
    avcodec_context->codec_id = output_format->video_codec;
    //2.2 设置编码器类型->视频编码器
    avcodec_context->codec_type = AVMEDIA_TYPE_VIDEO;
    //2.3 设置读取像素数据格式->编码的是像素数据格式->YUV420P
    //注意：这个类型是根据解码的时候指定的解码的视频像素数据格式类型
    avcodec_context->pix_fmt = AV_PIX_FMT_YUV420P;
    //2.4设置视频宽高
    avcodec_context->width = 640;
    avcodec_context->height = 352;
    //2.5 设置帧率->每秒25帧   fps:frame per seconed
    avcodec_context->time_base.num = 1;
    avcodec_context->time_base.den = 25;
    //2.6 设置码率
    //2.6.1 什么是码率  bps: bit per seconed
    //每秒传输的数据量大小
    //目的：视频处理->视频码率
    
    //2.6.2
    //一般用kbps表示:千位每秒。  KByteps：千字节每秒
    //但这里是bps单位
    //1KByteps = 8kbps
    //码率=视频大小/时间
    //例如test.mov 时间=24.37秒，文件大小=1.73MB，
    //码率(比特率) = 1.73MB/24.37s = 1.73 * 1024 * 8 / 24.37  =  581kbps
    //但其实这里的1.73不准确，是整个文件的大小，真正的码率是468 kbps
    avcodec_context->bit_rate = 468000;//bps
    
    //2.7设置GOP影响到视频质量问题->画面组->一组连续画面
    //MPEG格式画面类型：3种类型->IPB
    //I:内部编码帧->原始帧,原始视频数据->完整画面（关键帧，如果没有I帧无法进行编解码）
    //视频的第一帧一般都是I帧
    //P:向前预测帧->预测前面的一帧类型，处理数据(前面->I帧、P帧)
    //B:双向预测帧->依赖网络 依赖解码性能 依赖前后两帧，但压缩率高
    //每250帧插入一个I帧（249个P帧），I帧越少视频越小->默认值 一样
    avcodec_context->gop_size = 250;
    
    //2.8 设置量化参数
    //总结：量化洗漱越小，视频越是清晰
    //一般情况下都是默认值  就是以下
    avcodec_context->qmin = 10;
    avcodec_context->qmax = 51;
    
    //2.9设置b帧最大值
    avcodec_context->max_b_frames = 0;
    
    //第二点：查找解码器
    //原因：默认情况下FFMPEG没有编译xh264库  可以从官方下载（x264官网）
    AVCodec *avcodec = avcodec_find_encoder(avcodec_context->codec_id);
    if (avcodec == NULL) {
        NSLog(@"找不到编码器");
        return;
    }
    
    //第六步：打开h264编码器
    if (avcodec_open2(avcodec_context, avcodec, NULL) < 0) {
        NSLog(@"打开编码器失败");
        return;
    }
    
    //第六步：打开h264编码器
    //缺少优化步骤？
    //编码延时问题
    //编码选项->编码设置
    AVDictionary *param = 0;
    if (avcodec_context->codec_id == AV_CODEC_ID_H264) {
        //需要查看x264源码->x264.c文件
        //第一个值：预备参数
        //key: preset
        //value: slow->慢
        //value: superfast->超快
        av_dict_set(&param, "preset", "slow", 0);
        //第二个值：调优
        //key: tune->调优
        //value: zerolatency->零延迟
        av_dict_set(&param, "tune", "zerolatency", 0);
    }
    
    //第七步：写入文件头信息
    avformat_write_header(avformat_context, NULL);
    
    //第八步：循环编码YUV文件->视频像素数据(yuv格式)->编码->视频压缩数据(h264格式)
    //8.1打开文件
    //定义一个缓冲区
    //作用：缓存一帧视频像素数据
    
    //8.1.2 获取缓冲区的大小
    int buffer_size = av_image_get_buffer_size(avcodec_context->pix_fmt,
                             avcodec_context->width,
                             avcodec_context->height,
                             1);
    
    //8.1.3创建一个缓冲区
    uint8_t *out_buffer = (uint8_t *)av_malloc(buffer_size);
    //size
    int y_size = avcodec_context->width * avcodec_context->height;
    
    //8.1.1 创建AVFrame->ffmpeg数据类型
    //将void *restrict->转成AVFrame->ffmpeg数据类型
    //开辟了一块内存空间
    AVFrame *avframe_in = av_frame_alloc();
    //设置这块内存空间的类型和缓冲区的类型,保持一致,这句其实也有一个作用是将AVframe与outbuffer绑定
    av_image_fill_arrays(avframe_in->data,
                         avframe_in->linesize,
                         out_buffer,
                         avcodec_context->pix_fmt,
                         avcodec_context->width,
                         avcodec_context->height,
                         1);
    
    //8.1.4打开输入文件
    const char *cinFilePath = [filePath UTF8String];
    FILE *in_file= fopen(cinFilePath, "rb");
    if (!in_file) {
        NSLog(@"文件不存在");
        return;
    }
    
    int i = 0;
    //9.2接收一帧书品像素数据 编码为 视频压缩数据格式
    AVPacket *packet = (AVPacket *)av_malloc(sizeof(AVPacket));
    int result = 0;
    while (true) {
        //8.1 从yuv文件里面读取到缓冲区
        //y_size + y_size/2是所有的y,u,v数据总量
        if (fread(out_buffer, 1, y_size + y_size/2, in_file) <= 0) {
            NSLog(@"读取完毕");
            break;
        } else if (feof(in_file)) {
            NSLog(@"读取到结尾");
            break;
        }
        
        //8.2将缓冲区数据->转成AVFrame类型
        //给AVFrame填充数据
        //8.2.3 void *restrict转成AVFrame转成ffmpeg类型
        //y
        avframe_in->data[0] = out_buffer;
        //u
        avframe_in->data[1] = out_buffer + y_size;
        //v
        avframe_in->data[2] = out_buffer + y_size + 1/4*y_size;
        //设置帧数
        avframe_in->pts = i++;
        
        //总结 这样我们AVFrame就有数据了
        
        //第九步
        //9,1发送一帧视频像素数据
        avcodec_send_frame(avcodec_context, avframe_in);
        //9.2接收一帧书品像素数据 编码为 视频压缩数据格式
        result = avcodec_receive_packet(avcodec_context, packet);
        //9.3判定是否编码成功
        if (result == 0) {
            NSLog(@"编码成功");
            //第十部：将视频压缩数据  写入输出文件中 outFilePath
            packet->stream_index = av_video_steam->index;
            //这里是从开头绑定的format_context绑定的outputFormat,然后format_context就有了AVIOContext，AVIOContext又在开头绑定了输出文件，所以这一步可以把frame直接写入文件
            result = av_write_frame(avformat_context, packet);
            if (result < 0) {
                NSLog(@"输出一帧失败");
                return;
            }
        }
        
    }
    
    //第11步：写入剩余帧数据->可能没有
    flush_encoder(avformat_context, 0);
    
    //第12步：写入文件尾部信息
    av_write_trailer(avformat_context);
    
    //第13步：释放内存
    avcodec_close(avcodec_context);
    av_free(avframe_in);
    av_free(out_buffer);
    av_packet_free(&packet);
    avio_close(avformat_context->pb);
    avformat_free_context(avformat_context);
    fclose(in_file);
    
}

@end

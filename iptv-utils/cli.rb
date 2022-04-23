class Time
  def to_iptv
    self.strftime("%Y%m%d%H%M00")
  end
end

module IPTV
  module CLI
    extend Dry::CLI::Registry
    
    class Channels < Dry::CLI::Command
      desc "列出频道"
      argument :keyword, desc: "搜索关键词"

      def call(**options)
        channels = CHANNELS
        channels = channels.filter { |c| c["name"].include?(options[:keyword]) } if options[:keyword]
        channels.each { |channel| puts "#{channel["id"]}: #{channel["name"]}" }
      end
    end

    class Live < Dry::CLI::Command
      desc "观看直播"
      argument :id, required: true, desc: "频道 ID"

      def call(id:, **)
        channel = CHANNELS.filter { |c| c["id"] == id.to_i }.first
        if channel.nil?
          puts "找不到该频道 ID" 
          exit 1
        end
        puts "正在观看 #{channel["name"]} 直播"
        `open #{channel["url"]}?playseek=#{Time.now.to_iptv}-#{(Time.now + 4*60*60).to_iptv}`
      end
    end

    class Playback < Dry::CLI::Command
      desc "观看回放"
      argument :id, required: true, desc: "频道 ID"
      argument :start, required: true, desc: "起始时间"
      argument :stop, required: true, desc: "结束时间"

      def call(id:, start:, stop:, **)
        channel = CHANNELS.filter { |c| c["id"] == id.to_i }.first
        if channel.nil?
          puts "找不到该频道 ID" 
          exit 1
        end

        start_time = Time.parse(start)
        stop_time = Time.parse(stop)

        puts "正在回放 #{channel["name"]} #{start_time.to_s} 到 #{stop_time.to_s}"
        `open #{channel["url"]}?playseek=#{start_time.to_iptv}-#{stop_time.to_iptv}`
      end
    end

    class Record < Dry::CLI::Command
      desc "保存录像到文件 (需要安装 ffmpeg)"
      argument :id, required: true, desc: "频道 ID"
      argument :start, required: true, desc: "起始时间"
      argument :stop, required: true, desc: "结束时间"
      argument :filename, required: true, desc: "保存文件名，推荐 flv 格式"

      def call(id:, start:, stop:, filename:, **)
        channel = CHANNELS.filter { |c| c["id"] == id.to_i }.first
        if channel.nil?
          puts "找不到该频道 ID" 
          exit 1
        end

        start_time = Time.parse(start)
        stop_time = Time.parse(stop)

        puts "正在录像 #{channel["name"]} #{start_time.to_s} 到 #{stop_time.to_s} 保存到文件 #{filename}"
        system(
          "ffmpeg",
          "-i",
          "#{channel["url"]}?playseek=#{start_time.to_iptv}-#{stop_time.to_iptv}",
          "-c:v",
          "copy",
          "-c:a",
          "aac",
          filename
        )
      end
    end

    register "channels", Channels
    register "live", Live
    register "playback", Playback
    register "record", Record
  end
end

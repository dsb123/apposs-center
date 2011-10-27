# coding: utf-8
require 'open-uri'
require 'json'
module Tool

  class AppLoad
    def initialize ids
      result = {}
      Room.all.each{ |room| result.update(room.name => room) }
      @room_map = result
      @ids = ids
      @room_lock = Mutex.new
      @id_lock = Mutex.new
    end

    def add_loader
      Thread.new do |t|
        while(app_id = get_id())
          do_load app_id
        end
      end
    end

    def get_id
      @id_lock.synchronize{
        @ids.shift
      }
    end

    def do_load app_id
      app = App.find app_id
      p "app: #{app}"
      name = build_name app
      url  = "http://opsfree.corp.taobao.com:9999/products/dumptree?_username=droid/droid&notree=1&leafname=#{URI.escape name}"
      data = try_url url
      if data.size == 0
        $stderr.puts "没有发现数据: #{name} - #{url}"
        return
      end
      p "load #{app_id} #{name} - #{url}"

      data[0]["opsfree_product.#{name}"].each{|node_group_data|
#        node_group_name = node_group_data['nodegroup_info']['detail']['nodegroup_name']
        node_group_data['child'].each{|machine_data|
          room = get_and_update_room machine_data['site']
          attributes = {
            :host => machine_data['nodename'], # 可选 dns_ip
            :name => machine_data['nodename'],
            :room_id => room.id,
            :port => 22,
            :app_id => app_id
          }
          
          if machine_data['state']=='working_offline'
            ::Machine.where(:name => machine_data['nodename']).destroy_all
          elsif machine_data['state']=='working_online'
            if ::Machine.where(:name => machine_data['nodename']).first.nil?
              ::Machine.create(attributes)
            else
              p "机器重名 - #{machine_data['nodename']}"
            end
          else
            p "未知的机器状态：#{machine_data['state']}"
          end

        }
      }
    end

    def try_url(url)
      data = nil
      3.times.each{
        begin
          data = JSON.parse open(url).read
        rescue
          sleep 1
        else
          break
        end
      }
      data || []
    end

    def get_and_update_room room_name
      @room_lock.synchronize{
        if (room = @room_map[room_name]).nil?
          room = Room.create( :name => room_name )
          @room_map.update(room_name => room)
        end
        room
      }
    end

    def build_name(app)
      name = app.name
      while(app.parent_id > 0)
        app = app.parent
        name = "#{app.name}.#{name}"
      end
      "淘宝网.#{name}"
    end

    def hold app
      app.children.each{|child|
        hold child
      }
      app.hold
    end


  end
end

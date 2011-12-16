class ApiController < ApplicationController
  def commands
  	room = Room.where(:name => params[:room_name]).first
    if room.nil?
      render :text => ""
    else
      # 查询参数包括机房的 name 和 id，是考虑到 room 表的name字段发生变动，
      # 此时应该谨慎处理，不下发相应的命令
      if params[:reload]
        oper_query = Directive.with_state(:init,:ready,:running)
      else
        oper_query = Directive.with_state(:init)
      end
      render :text => oper_query.where(:room_id => room.id, :room_name => room.name).collect{|directive|
        directive.download
        directive.invoke unless directive.has_operation?
        "#{directive.machine_host}:#{directive.command_name}:#{directive.id}"
      }.join("\n")
    end
  end
  
  #{host,Host},{oid,DirectiveId}
  def run
    Directive.find(params[:oid]).invoke
    render :text => ''
  end
  
  # {isok,atom_to_list(IsOk)},{host,Host},{oid,DirectiveId},{body,Body}
  def callback
    directive = Directive.where(:id => params[:oid]).first
    directive.callback(
        "true"==params[:isok], params[:body]
    ) if directive
  	render :text => ''
  end
  
  def load_hosts
    hosts = params[:hosts].split("|")[0,9] #考虑到性能，仅取前10个，其余下次再获取
    render :text => Machine.where(:host => hosts).collect{|m|
      "host=#{m.host},port=#{m.port || 22},user=#{m.user},password=#{m.password},state=#{m.state}"
    }.join("\n")
  end
  
  def packages
    name,version,branch = params[:name], params[:version], params[:branch]
    software = Software.where(:name => name).first
    if not software
      render :text => "no_software"
    elsif (app = software.app).nil?
      render :text => "no_app"
    else
      if request.post?
        if(app.release_packs.where(:version => version, :branch => branch).count == 0)
          release_pack = app.release_packs.create :version => version, :branch => branch          
          release_pack.use
        end
        render :text => "ok"
      else
        render :text => app.properties[ReleasePack::NAME] || ""
      end
    end
  end
  
  def machine_on
    begin 
      m = Machine.find params[:id]
      result = m.send params[:event].to_sym
      render :text => result
    rescue Exception => e
      render :status => 404, :text => e.to_s
    end
  end
end

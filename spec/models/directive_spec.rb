# coding: utf-8
require 'spec_helper'

describe Directive do

  fixtures :operations, :machines, :operation_templates
  
  it "支持对内容的简易参数替换" do
    directive = Directive.create(
      :operation_id => 1,
      :command_name => "echo $param1 $param2 $ param1 $param1",
      :params => {:param1 => 'value1', 'param2' => 'value2' }
    )
    directive.command_name.should == 'echo value1 value2 $ param1 value1'
  end

  it "正常 生命周期迁移" do
    directive = create_and_change_state_until_running
    directive.callback(true, "指令执行完毕")
    directive.state.should == 'done'
    directive.response.should == '指令执行完毕'
  end

  it "异常 生命周期迁移" do
    directive = create_and_change_state_until_running
    directive.callback(false, "指令运行失败")
    directive.state.should == 'failure'
    directive.response.should == '指令运行失败'
    directive.operation.state.should == 'failure'
    directive.machine.state.should == 'pause'
    directive.ack
    directive.state.should == 'done'
  end
  
  it "正常结束时自动尝试关闭操作" do
    app = App.first
    o = app.operation_templates.last.gen_operation(
      User.first, app.machines.collect{|m| m.id}[0..1]
    )
    o.state.should == 'init'
    o.directives.each_with_index do |directive,index|
      directive.download;
      directive.state.should == 'ready'
      directive.invoke;
      directive.state.should == 'running'
      directive.ok;
      directive.state.should == 'done'
    end
    o.reload #回调操作是对数据库的更新，因此这里的旧数据需要reload
    o.state.should == 'done'
  end
  
  it "异常结束时不关闭操作，ack后尝试关闭操作" do
    app = App.first
    o = app.operation_templates.last.gen_operation(
      User.first, app.machines.collect{|m| m.id}[0..1]
    )
    o.state.should == 'init'
    o.directives.each_with_index do |directive,index|
      directive.download;
      directive.state.should == 'ready'
      directive.invoke;
      directive.state.should == 'running'
      if index % 2 == 0
        directive.error;
        directive.state.should == 'failure'
      else
        directive.ok;
        directive.state.should == 'done'
      end
    end
    o.reload #回调操作是对数据库的更新，因此这里的旧数据需要reload
    o.state.should == 'failure'
    o.directives.each do |directive|
      directive.ack
      directive.state.should == 'done'
    end
    o.reload # 同上
    o.state.should == 'done'
  end
  
  def create_and_change_state_until_running
    host = 'localhost'
    machine = Machine.where(:host => host).first
    directive = Directive.create(
      :operation_id => 1, :machine_host => host, :machine => machine
    )
    directive.state.should == 'init'
    directive.download
    directive.state.should == 'ready'
    directive.invoke
    directive.state.should == 'running'
    directive
  end
end

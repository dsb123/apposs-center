class App < ActiveRecord::Base

  acts_as_tree

  scope :reals, where(:virtual => false, :state => 'running')

  # People
  has_many :acls, :as => :resource, :class_name => 'Stakeholder'

  has_many :operators, :through => :acls, :class_name => 'User'

  has_many :release_packs

  has_many :softwares

  # Machine
  has_many :machines

  has_many :operation_templates
  
  has_many :operations
  
  has_many :envs do
    def [] name, creatable=false
      if creatable
        where(:name => name).first || create(:name => name)
      else
        where(:name => name).first
      end
    end
  end

  has_many :properties, :as => :resource do
    def [] name1
      item = where(:name => name1).first
      item.value if item
    end

    def []=name,value,locked=false
      item = where(:name => name).first
      if item.nil?
        new(:name => name, :value => value, :locked => locked).save!
      else
        item.update_attributes(:value => value, :locked => locked) && item
      end
    end

    def pairs
      all.inject({}){|hash,env| hash.update(env.name => env.value) }
      end
  end

  after_create :add_property

  def add_property
    properties[:app_id, self.id] = true
  end
  
  def to_s
  	send :name
  end

  # running 表示应用运行中，hold 表示暂时标记为不可用，offline 表示应用下线
  state_machine :state, :initial => :running do
    event :pause do transition :running => :hold end
    event :use do transition :hold => :running end
    event :stop do transition [:running, :hold] => :offline end
  end

end

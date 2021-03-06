require File.dirname(__FILE__) + '/../spec_helper'

describe PageFactory::Manager do
  dataset do
    create_record :page, :managed, :title => 'managed', :slug => 'managed', :breadcrumb => 'managed', :class_name => 'ManagedPage'
    create_record :page, :plain, :title => 'plain', :slug => 'plain', :breadcrumb => 'plain'
    create_record :page, :other, :title => 'other', :slug => 'other', :breadcrumb => 'other', :class_name => 'OtherPage'
    create_record :page_part, :existing, :name => 'existing'
    create_record :page_part, :old, :name => 'old'
    create_record :page_part, :new, :name => 'new'
    create_record :page_field, :field, :name => 'field'
  end

  class ManagedPage < Page
    part 'existing'
    part 'new'
    field 'field'
  end

  before do
    @managed, @plain, @existing, @old, @new, @field =
    pages(:managed), pages(:plain), page_parts(:existing), page_parts(:old), page_parts(:new), page_fields(:field)
  end

  describe ".prune_parts!" do
    it "should remove vestigial parts" do
      @managed.parts.concat [@existing, @old]
      PageFactory::Manager.prune_parts!
      @managed.reload.parts.should_not include(@old)
    end

    it "should leave listed parts alone" do
      @managed.parts.concat [@existing, @old]
      PageFactory::Manager.prune_parts!
      @managed.reload.parts.should include(@existing)
    end

    it "should operate on a single subclass" do
      @plain.parts.concat [old = @old.clone]
      @managed.parts.concat [@old]
      PageFactory::Manager.prune_parts! ManagedPage
      @plain.parts.should include(old)
      @managed.reload.parts.should_not include(@old)
    end
  end
  
  describe ".sync_parts!" do
    class AddPartClass < ActiveRecord::Migration
      def self.up
        add_column :page_parts, :part_class, :string
        PagePart.reset_column_information
      end

      def self.down
        remove_column :page_parts, :part_class
        PagePart.reset_column_information
      end
    end

    class SubPagePart < PagePart ; end

    before :all do
      ActiveRecord::Migration.verbose = false
      AddPartClass.up
      PagePart.class_eval do
        set_inheritance_column :part_class
      end
    end

    after :all do
      AddPartClass.down
      PagePart.class_eval do
        set_inheritance_column nil
      end
    end

    before :each do
      @part = SubPagePart.new(:name => 'new')
      @managed.parts = [@part]
    end

    it "should delete parts whose classes don't match" do
      PageFactory::Manager.sync_parts!
      @managed.reload.parts.should_not include(@new)
    end

    it "should replace parts whose classes don't match" do
      PageFactory::Manager.sync_parts!
      @managed.reload.parts.detect { |p| p.name == 'new'}.class.should == PagePart
    end

    it "should leave synced parts alone" do
      @managed.parts = [@new]
      PageFactory::Manager.sync_parts!
      @managed.reload.parts.should eql([@new])
    end

    it "should operate on a single subclass" do
      c = @part.clone
      @plain.parts = [c]
      PageFactory::Manager.sync_parts! :ManagedPage
      @plain.reload.parts.should include(c)
    end
  end

  describe ".update_parts" do
    it "should add missing parts" do
      @managed.parts.should be_empty
      PageFactory::Manager.update_parts
      @managed.parts.reload.map(&:name).should include('new')
    end

    it "should not duplicate existing parts" do
      @managed.parts.concat [@new, @existing]
      @managed.parts.reload
      lambda { PageFactory::Manager.update_parts }.should_not change(@managed.parts, :size)
    end

    it "should not replace matching parts" do
      @managed.parts.concat [@new, @existing]
      PageFactory::Manager.update_parts
      @managed.reload
      @managed.parts.should include(@new)
      @managed.parts.should include(@existing)
    end

    it "should operate on a single subclasses" do
      @plain.parts = [e = @existing.clone]
      PageFactory::Manager.update_parts :ManagedPage
      @plain.reload.parts.should == [e]
    end
  end

  describe ".prune_fields!" do
    it "should remove vestigial fields" do
      @managed.fields << f = PageField.new(:name => "old")
      PageFactory::Manager.prune_fields!
      @managed.fields.reload.should_not include(f)
    end

    it "should leave listed fields alone" do
     @managed.fields.concat [@field, PageField.new(:name => "old")]
     PageFactory::Manager.prune_fields!
     @managed.fields.reload.should == [@field]
    end

    it "should operate on a single subclass" do
      f = PageField.new(:name => "old")
      @managed.fields.concat [f]
      @plain.fields.concat [c = f.clone]
      PageFactory::Manager.prune_fields!
      @plain.fields.should include(c)
      @managed.fields.should_not include(f)
    end
  end

  describe ".update_fields" do
    it "should add missing fields" do
      @managed.parts.should be_empty
      PageFactory::Manager.update_fields
      @managed.fields.reload.map(&:name).should include('field')
    end

    it "should not duplicate existing fields" do
      @managed.fields.concat [@field]
      lambda { PageFactory::Manager.update_fields }.should_not change(@managed.parts, :size)
    end

    it "should not replace matching fields" do
      @managed.fields.concat [@field]
      PageFactory::Manager.update_fields
      @managed.reload
      @managed.fields.should include(@field)
    end

    it "should operate on a single subclass" do
      @plain.fields = [f = @field.clone]
      PageFactory::Manager.update_fields
      @plain.reload.fields.should == [f]
    end
  end
  
  describe ".sync_layouts!" do
    dataset do
      create_record :layout, :one, :name => 'Layout One'
      create_record :layout, :two, :name => 'Layout Two'
    end
    ManagedPage.layout 'Layout One'

    before do
      @managed.layout = layouts(:two)
      @managed.save
    end

    it "should change page layout to match factory" do
      PageFactory::Manager.sync_layouts!
      @managed.reload.layout.should eql(layouts(:one))
    end

    it "should operate on a single factory" do
      PageFactory::Manager.sync_layouts! :ManagedPage
      @plain.reload.layout.should_not eql(layouts(:one))
    end
  end

end

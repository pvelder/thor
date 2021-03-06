require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Thor::Group do
  describe "task" do
    it "allows to use private methods from parent class as tasks" do
      ChildGroup.start.should == ["bar", "foo", "baz"]
      ChildGroup.new.baz("bar").should == "bar"
    end
  end

  describe "#start" do
    it "invokes all the tasks under the Thor group" do
      MyCounter.start(["1", "2", "--third", "3"]).should == [ 1, 2, 3 ]
    end

    it "uses argument default value" do
      MyCounter.start(["1", "--third", "3"]).should == [ 1, 2, 3 ]
    end

    it "invokes all the tasks in the Thor group and his parents" do
      BrokenCounter.start(["1", "2", "--third", "3"]).should == [ nil, 2, 3, false, 5 ]
    end

    it "raises an error if a required argument is added after a non-required" do
      lambda {
        MyCounter.argument(:foo, :type => :string)
      }.should raise_error(ArgumentError, 'You cannot have "foo" as required argument after the non-required argument "second".')
    end

    it "raises when an exception happens within the task call" do
      lambda { BrokenCounter.start(["1", "2", "--fail"]) }.should raise_error
    end

    it "raises an error when a Thor group task expects arguments" do
      lambda { WhinyGenerator.start }.should raise_error(ArgumentError, /thor wrong_arity takes 1 argument, but it should not/)
    end

    it "invokes help message if any of the shortcuts is given" do
      MyCounter.should_receive(:help)
      MyCounter.start(["-h"])
    end
  end

  describe "#desc" do
    it "sets the description for a given class" do
      MyCounter.desc.should == "Description:\n  This generator runs three tasks: one, two and three.\n"
    end

    it "can be inherited" do
      BrokenCounter.desc.should == "Description:\n  This generator runs three tasks: one, two and three.\n"
    end

    it "can be nil" do
      WhinyGenerator.desc.should be_nil
    end
  end

  describe "#help" do
    before(:each) do
      @content = capture(:stdout){ MyCounter.help(Thor::Base.shell.new) }
    end

    it "provides usage information" do
      @content.should =~ /my_counter N \[N\]/
    end

    it "shows description" do
      @content.should =~ /Description:/
      @content.should =~ /This generator runs three tasks: one, two and three./
    end

    it "shows options information" do
      @content.should =~ /Options/
      @content.should =~ /\[\-\-third=THREE\]/
    end
  end

  describe "#invoke" do
    before(:each) do
      @content = capture(:stdout){ E.start }
    end

    it "allows to invoke a class from the class binding" do
      @content.should =~ /1\n2\n3\n4\n5\n/
    end

    it "shows invocation information to the user" do
      @content.should =~ /invoke  Defined/
    end

    it "uses padding on status generated by the invoked class" do
      @content.should =~ /finished    counting/
    end

    it "allows invocation to be configured with blocks" do
      capture(:stdout) do
        F.start.should == ["Valim, Jose"]
      end
    end

    it "shows invoked options on help" do
      content = capture(:stdout){ E.help(Thor::Base.shell.new) }
      content.should =~ /Defined options:/
      content.should =~ /\[--unused\]/
      content.should =~ /# This option has no use/
    end
  end

  describe "#invoke_from_option" do
    describe "with default type" do
      before(:each) do
        @content = capture(:stdout){ G.start }
      end

      it "allows to invoke a class from the class binding by a default option" do
        @content.should =~ /1\n2\n3\n4\n5\n/
      end

      it "does not invoke if the option is nil" do
        capture(:stdout){ G.start(["--skip-invoked"]) }.should_not =~ /invoke/
      end

      it "prints a message if invocation cannot be found" do
        content = capture(:stdout){ G.start(["--invoked", "unknown"]) }
        content.should =~ /error  unknown \[not found\]/
      end

      it "allows to invoke a class from the class binding by the given option" do
        content = capture(:stdout){ G.start(["--invoked", "e"]) }
        content.should =~ /invoke  e/
      end

      it "shows invocation information to the user" do
        @content.should =~ /invoke  defined/
      end

      it "uses padding on status generated by the invoked class" do
        @content.should =~ /finished    counting/
      end

      it "shows invoked options on help" do
        content = capture(:stdout){ G.help(Thor::Base.shell.new) }
        content.should =~ /defined options:/
        content.should =~ /\[--unused\]/
        content.should =~ /# This option has no use/
      end
    end

    describe "with boolean type" do
      before(:each) do
        @content = capture(:stdout){ H.start }
      end

      it "allows to invoke a class from the class binding by a default option" do
        @content.should =~ /1\n2\n3\n4\n5\n/
      end

      it "does not invoke if the option is false" do
        capture(:stdout){ H.start(["--no-defined"]) }.should_not =~ /invoke/
      end

      it "shows invocation information to the user" do
        @content.should =~ /invoke  defined/
      end

      it "uses padding on status generated by the invoked class" do
        @content.should =~ /finished    counting/
      end

      it "shows invoked options on help" do
        content = capture(:stdout){ H.help(Thor::Base.shell.new) }
        content.should =~ /defined options:/
        content.should =~ /\[--unused\]/
        content.should =~ /# This option has no use/
      end
    end
  end

  describe "edge-cases" do
    it "can handle boolean options followed by arguments" do
      klass = Class.new(Thor::Group) do
        desc "say hi to name"
        argument :name, :type => :string
        class_option :loud, :type => :boolean

        def hi
          name.upcase! if options[:loud]
          "Hi #{name}"
        end
      end

      klass.start(["jose"]).should == ["Hi jose"]
      klass.start(["jose", "--loud"]).should == ["Hi JOSE"]
      klass.start(["--loud", "jose"]).should == ["Hi JOSE"]
    end

    it "provides extra args as `args`" do
      klass = Class.new(Thor::Group) do
        desc "say hi to name"
        argument :name, :type => :string
        class_option :loud, :type => :boolean

        def hi
          name.upcase! if options[:loud]
          out = "Hi #{name}"
          out << ": " << args.join(", ") unless args.empty?
          out
        end
      end

      klass.start(["jose"]).should == ["Hi jose"]
      klass.start(["jose", "--loud"]).should == ["Hi JOSE"]
      klass.start(["--loud", "jose"]).should == ["Hi JOSE"]
    end
  end
end

class LanguagePack::Helpers::RakeRunner
  include LanguagePack::ShellHelpers
  alias :exec_in_shell :run

  class RakeTask
    include LanguagePack::ShellHelpers

    attr_accessor :output, :time, :command, :status, :task_defined
    ALLOWED = [:pass, :fail, :no_load, :not_found]

    def initialize(task, command = nil)
      @task    = task
      command  = "env PATH=$PATH:bin bundle exec rake #{task} 2>&1" if command.nil?
      raise "expect #{command} to contain #{task}" unless command.include?(task)

      @command = command
      @status  = :nil
      @output  = ""
    end

    def task_defined?
      @task_defined
    end
    alias :is_defined? :task_defined

    def success?
      status == :pass
    end

    def status?
      @status && @status != :nil
    end

    def status
      raise "Status not set for #{self.inspect}" if @status == :nil
      raise "Not allowed status: #{@status} for #{self.inspect}" unless ALLOWED.include?(@status)
      @status
    end

    def run(cmd = nil)
      cmd = cmd || @command
      puts "Running: rake #{@task}"
      time = Benchmark.realtime do
        self.output = pipe(cmd)
      end
      self.time = time

      if $?.success?
        self.status = :pass
      else
        self.status = :fail
      end
      return self
    end
  end

  def task

  end

  def initialize(has_rake = true)
    @has_rake = has_rake
    if has_rake
      load_rake_tasks
    else
      @rake_tasks    = ""
      @rake_can_load = false
    end
  end

  def cannot_load_rake?
    !rake_can_load?
  end

  def rake_can_load?
    @rake_can_load
  end

  def instrument(*args, &block)
    LanguagePack::Instrument.instrument(*args, &block)
  end

  def load_rake_tasks
    instrument "ruby.rake_task_defined" do
      @rake_tasks    ||= exec_in_shell("env PATH=$PATH bundle exec rake -P")
      @rake_can_load ||= $?.success?
      @rake_tasks
    end
  end

  def load_rake_tasks!
    out = load_rake_tasks
    msg =  "Could not detect rake tasks\n"
    msg << "ensure you can run `$ bundle exec rake -P` against your app with no environment variables present:\n"
    msg << out
    error(msg) if cannot_load_rake?
    return self
  end

  def task_defined?(task)
    @task_available ||= Hash.new {|hash, key| hash[key] = @rake_tasks.include?(key) }
    @task_available[task]
  end

  def not_found?(task)
    !task_defined?(task)
  end

  def task(rake_task, command = nil)
    t = RakeTask.new(rake_task, command)
    t.task_defined = task_defined?(rake_task)
    t
  end

  def run(task, command = nil)
    return true unless @has_rake
    self.task(task, command).run
  end
end

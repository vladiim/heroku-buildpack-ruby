class LanguagePack::NoLockfile < LanguagePack::Base
  def self.use?
    !File.exists?("Gemfile.lock")
  end

  def name
    "Ruby/NoLockfile"
  end

  def compile
    error LanguagePack::Helpers::BundlerWrapper::NoLockfileErrorMsg
  end
end

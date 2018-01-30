class FakeData
  def initialize; end

  def self.call(*args)
    new(*args).call
  end

  def call; end
end

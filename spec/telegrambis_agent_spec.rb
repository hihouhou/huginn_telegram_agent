require 'rails_helper'
require 'huginn_agent/spec_helper'

describe Agents::TelegrambisAgent do
  before(:each) do
    @valid_options = Agents::TelegrambisAgent.new.default_options
    @checker = Agents::TelegrambisAgent.new(:name => "TelegrambisAgent", :options => @valid_options)
    @checker.user = users(:bob)
    @checker.save!
  end

  pending "add specs here"
end

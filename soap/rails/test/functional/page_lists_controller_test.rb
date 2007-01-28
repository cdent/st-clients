require File.dirname(__FILE__) + '/../test_helper'
require 'page_lists_controller'

# Re-raise errors caught by the controller.
class PageListsController; def rescue_action(e) raise e end; end

class PageListsControllerTest < Test::Unit::TestCase
  def setup
    @controller = PageListsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end

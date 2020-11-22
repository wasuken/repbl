# coding: utf-8
require 'test_helper'

class RepoJobTest < ActiveJob::TestCase
  # test "the truth" do
  #   assert true
  # end
  test "insert test" do
    RepoJob.perform_now(:insert, "https://github.com/wasuken/weekly_report/archive/master.zip", "週報")
    assert(Repo.all.first.title == "週報")
  end
  test "update test" do
    RepoJob.perform_now(:insert, "https://github.com/wasuken/weekly_report/archive/master.zip", "週報")
    RepoJob.perform_now(:update, "https://github.com/wasuken/weekly_report/archive/master.zip", "週報(test)")
    assert(Repo.all.first.title == "週報(test)")
    assert(Repo.all.size == 1)
  end
  test "delete test" do
    RepoJob.perform_now(:insert, "https://github.com/wasuken/weekly_report/archive/master.zip", "週報")
    assert(Repo.all.size == 1)
    RepoJob.perform_now(:delete, "https://github.com/wasuken/weekly_report/archive/master.zip")
    assert(Repo.all.size.zero?)
  end
end

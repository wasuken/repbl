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
    all_size = Repo.all.size
    url = "https://github.com/wasuken/weekly_report/archive/master.zip"
    RepoJob.perform_now(:update, url, "週報(test)")
    assert(Repo.find_by(url: url).title == "週報(test)")
    assert(Repo.all.size == all_size)
  end
  test "delete test" do
    RepoJob.perform_now(:insert, "https://github.com/wasuken/weekly_report/archive/master.zip", "週報")
    assert(Repo.all.size == 1)
    RepoJob.perform_now(:delete, "https://github.com/wasuken/weekly_report/archive/master.zip")
    assert(Repo.all.size.zero?)
  end
  test "update more test" do
    url = "https://github.com/wasuken/weekly_report/archive/master.zip"
    RepoJob.perform_now(:insert, url, "週報")
    path = Path
             .where('name like ?', '%weekly_report%')
             .where('name like ?', '%.md')
             .first
    rfile = Rfile.find_by(path_id: path.id)
    update_contents = (rfile.contents + "hogehoge") * 20
    rfile.update(contents: update_contents)
    RepoJob.perform_now(:update, "https://github.com/wasuken/weekly_report/archive/master.zip", "週報")
    assert(Rfile.find(rfile.id).contents != update_contents)
  end
end

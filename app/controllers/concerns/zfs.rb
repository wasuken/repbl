# coding: utf-8
require 'zip'
require "open-uri"
require 'json'

module Zfs
  class ZFileSystem
    attr_accessor :path, :type, :id
    def initialize(type, path)
      @type = type
      @path = path
      @id = -1                  # APIとして送信する際にのみ利用。最悪な設計じゃん...。
    end
    def self.build(type, path)
      if type == :file
        ZFile.new(type, path)
      else
        ZDir.new(type, path)
      end
    end
  end

  class ZFile < ZFileSystem
    attr_accessor :contents
    def initialize(type, path, contents="")
      super(type, path)
      @contents = contents
    end
    def to_h
      h = {}
      h[:type] = @type
      h[:path] = @path
      h[:contents] = @contents unless @contents.size.zero?
      h[:id] = @id if @id.positive?
      h
    end
  end

  class ZDir < ZFileSystem
    attr_accessor :children
    def initialize(type, path)
      super(type, path)
      @path = path + "/" if @path[-1] != "/"
      @children = []
    end
    def insert(zfs)
      # puts "--- Debug self.path => #{@path}, zfs.path => #{zfs.path}"
      # root処理
      if @type == :root && @children.size.zero?
        @children.push(zfs)
      else
        # 同じものが存在しているばあい
        self_path = @path
        self_path = self_path[0..-2] if self_path[-1] == "/"
        zfs_path = zfs.path
        zfs_path = zfs_path[0..-2] if zfs_path[-1] == "/"
        if self_path == zfs_path
          # puts "Already exist path(#{zfs.path})."
          return
        # 直下の場合
        elsif File.join(zfs.path.split('/')[0..-2] + [""])[0..-2] == self_path
          @children.push(zfs)
        # 途中の道筋である場合
        elsif @children.select{|x| x.type == :directory}
                .find{|x| zfs.path.match("^#{x.path}") }
          @children.select{|x| x.type == :directory}
            .find{|x| zfs.path.match("^#{x.path}") }
            .insert(zfs)
        # childrenに候補がない場合
        else
          # 存在しないpath
          g_path_split = zfs.path.gsub(@path, '').split('/')[0..-2]
          if g_path_split.size >= 1
            cur = @path
            mini_root = nil
            g_path_split.each do |p|
              cur = File.join(cur, p)
              zfs = ZFileSystem.build(:directory, cur)
              if !mini_root.nil?
                mini_root.insert(zfs)
              else
                mini_root = zfs
              end
            end
            mini_root.insert(zfs)
            @children.push(mini_root)
          else
            puts "!!!!!! Error self.path => #{@path}, zfs.path => #{zfs.path}"
          end
        end
      end
    end
    def to_h
      h = {}
      h[:type] = @type
      h[:path] = @path
      h[:children] = @children.map(&:to_h)
      h[:id] = @id if @id.positive?
      h
    end
  end

  def exc_match(path, exc_ptns)
    return false if exc_ptns.size.zero?
    path.match(exc_ptns.first) || exc_match(path, exc_ptns[1..-1])
  end

  def remote_zip_to_zfs(url, file_match_ptn=".*", exc_ptns=["/\..*"])
    URI.open(url) do |file|
      # なんでここに非Factoryが!?
      root = ZDir.new(:root, "root")
      Zip::File.open_buffer(file.read) do |zf|
        zf.each do |entry|
          e_name_utf8 = entry.name.force_encoding('UTF-8')
          if (entry.ftype == :file && !e_name_utf8.match(file_match_ptn)) ||
             (entry.ftype == :directory && exc_match(entry.name, exc_ptns))
            next
          end
          if entry.ftype == :directory && e_name_utf8.match(file_match_ptn)
            next
          end
          zfs = ZFileSystem.build(entry.ftype, e_name_utf8)
          zfs.contents = entry.get_input_stream.read.force_encoding('UTF-8') if zfs.type == :file
          root.insert(zfs)
        end
      end
      root.children[0]
    end
  end
  def zfs_insert(zfs, repo_id, parent_id = nil)
    path = Path.create(path_id: parent_id, name: zfs.path)
    RepoPath.create(repo_id: repo_id, path_id: path.id)
    if zfs.type == :file
      Rfile.create(path_id: path.id, contents: zfs.contents)
    else
      Rdir.create(path_id: path.id)
      zfs.children.each do |z|
        zfs_insert(z, repo_id, path.id)
      end
    end
  end
  def zfs_update(zfs, repo_id, parent_id = nil)
    path = Path.find_by(name: zfs.path)
    unless path
      path = Path.create(path_id: parent_id, name: zfs.path)
      RepoPath.create(repo_id: repo_id, path_id: path.id)
    end
    if zfs.type == :file
      rfile = Rfile.find_by(path_id: path.id)
      if rfile && rfile.contents != zfs.contents
        rfile.update(contents: zfs.contents)
      elsif rfile
      else
        Rfile.create(path_id: path.id, contents: zfs.contents)
      end
    else
      rdir = Rdir.find_by(path_id: path.id)
      unless rdir
        Rdir.create(path_id: path.id)
      end
      zfs.children.each do |z|
        zfs_update(z, repo_id, path.id)
      end
    end
  end
  def repo_update(url, file_match_ptn=".*", exc_ptns=["/\..*"])
    repo_id = Repo.find_by(url: url).id
    inserted_path_list = []
    URI.open(url) do |file|
      # なんでここに非Factoryが!?
      root = ZDir.new(:root, "root")
      Zip::File.open_buffer(file.read) do |zf|
        zf.each do |entry|
          e_name_utf8 = entry.name.force_encoding('UTF-8')
          inserted_path_list << e_name_utf8
          if (entry.ftype == :file && !e_name_utf8.match(file_match_ptn)) ||
             (entry.ftype == :directory && exc_match(entry.name, exc_ptns))
            next
          end
          if entry.ftype == :directory && e_name_utf8.match(file_match_ptn)
            next
          end
          zfs = ZFileSystem.build(entry.ftype, e_name_utf8)
          zfs.contents = entry.get_input_stream.read.force_encoding('UTF-8') if zfs.type == :file
          root.insert(zfs)
        end
      end
      Path.joins('inner join repo_paths on repo_paths.path_id = paths.id')
        .where(repo_paths: {repo_id: repo_id})
        .select("paths.name as name")
        .all
        .each do |p|
        unless inserted_path_list.include?(p.name)
          Path.find_by(name: p.name).destroy
        end
      end
      zfs_update(root.children[0], repo_id)
    end
  end
  def dirs_files_to_zfs(dirs, files)
    root = ZFileSystem.build(:directory, dirs[0].name)
    dirs = dirs[1..-1]
    dirs.each do |d|
      root.insert(ZFileSystem.build(:directory, d.name))
    end
    files.each do |f|
      zfs = ZFileSystem.build(:file, f.name)
      zfs.id = f.id
      root.insert(zfs)
    end
    root
  end
  def repos_to_zfs(repo_id)
    dirs = Rdir.joins(:path)
             .joins("inner join repo_paths on repo_paths.path_id = paths.id")
             .where(repo_paths: {repo_id: repo_id})
             .select("paths.name as name")
             .all
             .sort{|a, b| a.name.split('/').select(&:empty?).size <=> b.name.split('/').select(&:empty?).size}
    files = Rfile.joins(:path)
              .joins("inner join repo_paths on repo_paths.path_id = paths.id")
              .where(repo_paths: {repo_id: repo_id})
              .select("paths.name as name, rfiles.id as id")
              .all
              .sort{|a, b| a.name.split('/').select(&:empty?).size <=> b.name.split('/').select(&:empty?).size}
    dirs_files_to_zfs(dirs, files)
  end
  def search_repos_to_zfs(repo_id, query)
    return repos_to_zfs if query.empty?
    dirs = Rdir.joins(:path)
             .joins("inner join repo_paths on repo_paths.path_id = paths.id")
             .where(repo_paths: {repo_id: repo_id})
             .select("paths.name as name")
             .all
             .sort{|a, b| a.name.split('/').select(&:empty?).size <=> b.name.split('/').select(&:empty?).size}
    files = Rfile.joins(:path)
              .joins("inner join repo_paths on repo_paths.path_id = paths.id")
              .where(repo_paths: {repo_id: repo_id})
              .where('rfiles.contents like ?', "%#{query}%")
              .select("paths.name as name, rfiles.id as id")
              .all
              .sort{|a, b| a.name.split('/').select(&:empty?).size <=> b.name.split('/').select(&:empty?).size}
    dirs_files_to_zfs(dirs, files)
  end
end

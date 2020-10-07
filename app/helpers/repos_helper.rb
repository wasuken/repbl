# coding: utf-8
require 'zip'
require "open-uri"
require 'json'

module ReposHelper
  class ZFileSystem
    attr_accessor :path, :type
    def initialize(type, path)
      @type = type
      @path = path
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
      @type = type
      @path = path
      @contents = contents
    end
    def to_h
      h = {}
      h[:type] = @type
      h[:path] = @path
      h[:contents] = @contents
      h
    end
  end

  class ZDir < ZFileSystem
    attr_accessor :children
    def initialize(type, path)
      @type = type
      @path = path
      @children = []
    end
    def insert(zfs)
      # puts "--- Debug self.path => #{@path}, zfs.path => #{zfs.path}"
      # root処理
      if (@type == :root && @children.size.zero?)
        @children.push(zfs)
      else
        # 直下の場合
        if File.join(zfs.path.split('/')[0..-2] + [""]) == @path
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
      h
    end
  end

  def exc_match(path, exc_ptns)
    return false if exc_ptns.size.zero?
    path.match(exc_ptns.first) || exc_match(path, exc_ptns[1..-1])
  end

  def remote_zip_to_zfs(url, file_match_ptn=".*", exc_ptns=["/\..*"])
    open(URI.escape(url)) do |file|
      root = ZDir.new(:root, "root")
      Zip::File.open_buffer(file.read) do |zf|
        zf.each do |entry|
          e_name_utf8 = entry.name.force_encoding('UTF-8')
          if (entry.ftype == :file && e_name_utf8.match(file_match_ptn)) ||
             (entry.ftype == :directory && !exc_match(entry.name, exc_ptns))
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
    path = Path.new(path_id: parent_id, name: zfs.path)
    RepoPath.create(repo_id: repo_id, path_id: path.id)
    if zfs.type == :file
      Rfile.create(path_id: path.id, contents: zfs.contents)
    else
      Rdir.create(path_id: path.id)
      zfs.children.select{|x| x.type == :directory}.each do |z|
        dir_hash_insert(z, path.id)
      end
    end
  end
end

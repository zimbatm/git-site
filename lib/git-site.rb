require 'grack/server'
require 'mimemagic'
require 'rack'
require 'rugged'

class GitSite
  def initialize(conf)
    @repo = Rugged::Repository.new(conf.repo)
    @grack = Grack::Server.new(
      #git_path: conf.repo,
      project_root: conf.repo,
      upload_path: true,
      receive_path: false, # Make that configurable ?
    )
    @index = conf.index

    # unless @repo.exists? conf.branch
    #   raise ArgumentError, "unknown ref #{conf.branch.inspect}"
    # end
    # @branch = conf[:branch]
  end

  def call(env)
    req = Rack::Request.new(env)

    # Normalize paths middleware
    path = normalized_path(req.path)
    return redirect_to(path) if path != req.path

    # Grack middleware
    resp = @grack.call(env)
    return resp if resp[0] != 404

    git_file(req)
  end


  def git_file(req)
    tree = @repo.lookup(@repo.head.target).tree

    path = req.path
    index_path = File.join(path, @index)

    blob = get_blob(tree, path)
    if blob
      return redirect_to path[0..-2] if path[-1] == "/"
    else
      blob = get_blob(tree, index_path)
      return r404(req) unless blob
      return redirect_to(path + "/") if path[-1] != "/"
      path = index_path
    end

    [
      200,
      {
        'Content-Type' => lookup_type(path, blob.content),
        'Content-Length' => blob.size.to_s,
      },
      [blob.content]
    ]
  end

  def get_blob(tree, path)
    path = path[1..-1] if path[0] == '/'
    path = path[0..-2] if path[-1] == '/'

    blob = path.split('/').inject(tree) do |tree, elem|
      return unless tree && tree.type == :tree
      obj = tree[elem]
      return unless obj
      @repo.lookup obj[:oid]
    end
    return unless blob.type == :blob
    blob
  end

  def lookup_type(path, content)
    mime = MimeMagic.by_path(path) || MimeMagic.by_magic(content)
    mime ? mime.type : 'text/plain'
  end

  def normalized_path(path)
    return "/" if path == "/"
    norm = File.expand_path path, '/'
    norm += "/" if path[-1] == "/"
    norm
  end

  def r404(req)
    [404, {}, ['not found']]
  end

  def redirect_to(path)
    p caller[0]
    [301, {"Location" => path}, []]
  end
end

desc 'Resets files to the state they were in the specified commit'
arg_name '<file> ...'
command [:reset, :restore] do |c|
  c.desc          'Use this specify which commit should be the used as reference'
  c.arg_name      'source'
  c.default_value 'head'
  c.flag          [:s, :source]

  c.action do |global_options, options, args|
    repository = SCV::Repository.new global_options[:dir]
    commit     = repository.resolve options[:source], :commit

    args.each do |file_path|
      repository.reset_file file_path, commit.id
    end
  end
end
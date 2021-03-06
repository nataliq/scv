desc 'Commits the current state of the working directory.'
arg_name ''
command :commit do |c|
  c.desc          'The commit message'
  c.arg_name      'message'
  c.flag          [:m, :message]

  c.desc          'The commit author name and email.'
  c.arg_name      'author'
  c.flag          :author

  c.desc          'Use this to override the timestamp of the commit.'
  c.arg_name      'date'
  c.default_value DateTime.now
  c.flag          :date

  c.desc          'Use this to replace the last commit'
  c.arg_name      'amend'
  c.switch        :amend

  c.action do |global_options, options, args|
    repository = global_options[:repository]
    repository_path  = "#{global_options[:dir]}/.scv"

    unless options[:amend]
      status = repository.status repository[:head, :commit], ignore: [/^\.|\/\./]

      if status.none? { |_, files| files.any? }
        raise 'No changes since last commit'
      end
    end

    if options[:author]
      author = options[:author]
    elsif repository.config['author']
      author = repository.config['author']
    else
      raise 'Please provide an author with --author="..." or set it globally with `scv config author ...`'
    end

    if options[:amend] and repository.head.nil?
      raise 'Amend requested but there are no commits'
    end

    if options[:message]
      commit_message = options[:message].strip
    else
      commit_message_file = "#{repository_path}/COMMIT_MESSAGE"

      if options[:amend]
        File.write commit_message_file, repository[:head, :commit].message
      end

      system "$EDITOR #{commit_message_file}"
      File.open(commit_message_file, 'r') do |file|
        commit_message = file.read.strip
      end
      FileUtils.rm commit_message_file
    end

    if commit_message.empty?
      raise 'The commit message cannot be empty'
    end

    date = options[:date].is_a?(String) ? DateTime.parse(options[:date]) : options[:date]

    parents = nil

    if options[:amend]
      parents = repository[:head, :commit].parents
    elsif repository.config['merge'] and repository.config['merge']['parents']
      # There is a merge waiting for a commit creation
      parents = repository.config['merge']['parents']

      repository.config['merge'] = {}
    end

    repository.commit commit_message,
                      author,
                      date,
                      parents: parents,
                      ignore:  [/^\.|\/\./]

    if parents
      repository.config.save
    end
  end
end
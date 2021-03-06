namespace :site do
  desc "Generate the site"
  task :build do
    # check_destination
    sh "bundle exec jekyll build"
  end

  desc "Generate the site and serve locally"
  task :serve do
    # check_destination
    sh "bundle exec jekyll serve"
  end

  desc "Generate the site, serve locally and watch for changes"
  task :watch do
    sh "bundle exec jekyll serve --watch"
  end

  desc "Generate the site and push changes to remote origin"
  task :deploy do
    # Detect pull request
    if ENV['TRAVIS_PULL_REQUEST'].to_s.to_i > 0
      puts 'Pull request detected. Not proceeding with deploy.'
      exit
    end

    # Configure git if this is run in Travis CI
    if ENV["TRAVIS"]
      sh "git config --global user.name '#{ENV['GIT_NAME']}'"
      sh "git config --global user.email '#{ENV['GIT_EMAIL']}'"
      sh "git config --global push.default simple"
      # USERNAME = `printf '%s' $(cd .. && printf '%s' ${PWD##*/})`
      USERNAME = `printf '%s' $(echo $TRAVIS_REPO_SLUG | cut --fields=1 --delimiter='/')`
      # REPO = `printf '%s' $(cd . && printf '%s\n' ${PWD##*/})`
      REPO = `printf '%s' $(echo $TRAVIS_REPO_SLUG | cut --fields=2 --delimiter='/')`
    else
      USERNAME = CONFIG["username"] || `printf '%s' $(cat .git/config | grep -e "url = " | cut --fields=2 --delimiter=: | cut --field=1 --delimiter=/)`
      REPO = CONFIG["repo"] || `printf '%s' $(cd . && printf '%s\n' ${PWD##*/})`
    end

    # Determine source and destination branch
    # User or organization: source -> master
    # Project: master -> gh-pages
    # Name of source branch for user/organization defaults to "source"
    if REPO == "#{USERNAME}.github.io".downcase
      SOURCE_BRANCH = CONFIG['branch'] || "source"
      DESTINATION_BRANCH = "master"
    else
      SOURCE_BRANCH = "master"
      DESTINATION_BRANCH = "gh-pages"
    end

    # Make sure destination folder exists as git repo
    # check_destination
    CONFIG["destination"] = "_deploy"

    # Creates git clone to update branch for publishing
    unless Dir.exist? CONFIG["destination"]
      unless ENV['GH_TOKEN'].to_s == ''
        sh "git clone https://${GIT_NAME}:${GH_TOKEN}@github.com/#{USERNAME}/#{REPO}.git #{CONFIG["destination"]}"
      else
        # Expecting that ssh keys exsist
        sh "git clone git@github.com:#{USERNAME}/#{REPO}.git #{CONFIG["destination"]}"
      end
    else
      abort ("Directory \'#{CONFIG["destination"]}\' exists!")
    end

    # Set branch
    sh "git checkout #{SOURCE_BRANCH}"
    Dir.chdir(CONFIG["destination"]) { sh "git checkout #{DESTINATION_BRANCH}" }

    # Generate the site
    sh "bundle exec jekyll build"

    if CONFIG["nojekyll"]
      # Remove all files from destination, execpt the .git directory
      # Then set Github not to process with Jekyll
      # Copy new build to destination
      Dir.chdir(CONFIG["destination"]) { sh "find . -maxdepth 1 -not -name .git -not -name . -exec rm --recursive --force {} \\;" }
      Dir.chdir(CONFIG["destination"]) { sh "touch .nojekyll" }
      sh "cp --recursive _site/* #{CONFIG["destination"]}"
    else
      Dir.chdir(CONFIG["destination"]) { sh "git merge #{SOURCE_BRANCH}" }
    end

    # Commit and push to github
    sha = `git log`.match(/[a-z0-9]{40}/)[0]
    Dir.chdir(CONFIG["destination"]) do
      sh "git add --all ."
      sh "git commit -m 'Updating to #{USERNAME}/#{REPO}@#{sha}.'"
      sh "git push --quiet origin #{DESTINATION_BRANCH}"
      puts "Pushed updated branch #{DESTINATION_BRANCH} to GitHub Pages"
    end

    sh "rm --recursive --force #{CONFIG["destination"]}"
  end
end

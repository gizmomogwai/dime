desc 'do clean'
task :clean do
  sh "dub clean"
end

desc 'test'
task :test do
  sh "dub test -c ut || dub test"
end

desc 'do a release build (after testing)'
task :build => [:test] do
  sh 'find . -name "*.d" | xargs dfmt'
  sh "dub clean"
  sh "dub build --build=release"
end

desc 'format'
task :format do
  sh "find . -name \"*.d\" | xargs dfmt -i"
end


desc 'build docs'
task :docs do
  sh "dub build -b ddox"
end

desc 'prepare docs'
task :prepare_docs do
  sh "rm -rf docs"
  sh "git clone -b gh-pages git@github.com:gizmomogwai/dime.git docs"
end

task :default => [:format, :build, :prepare_docs, :docs]

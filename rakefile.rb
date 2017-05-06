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
  sh "dub clean"
  sh "dub build --build=release"
end

task :default => [:build]

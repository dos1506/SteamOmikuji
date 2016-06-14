@path = '/home/dos/prog/steam/'

worker_processes 2
working_directory '.'

timeout 300
listen "#{@path}tmp/sockets/unicorn.sock"

pid "#{@path}tmp/pids/unicorn.pid"

#stderr_path "#{@path}log/unicorn.stderr.log"
#stdout_path "#{@path}log/unicorn.stdout.log"

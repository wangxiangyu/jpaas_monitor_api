    class Svn
        class << self
            def commit(working_path, message,username,password)
                sleep 0.2
                svn = `which svn`.strip
                out=`cd #{working_path} 2>&1 && #{svn} commit -m "#{message}" --username #{username} --password #{password} --no-auth-cache 2>&1`
                status= $?.success? ? 0 : -1
                {:rescode=>status,:msg=>out}
            end
 
            def add_all(working_path)
                svn = `which svn`.strip
                out=`cd #{working_path} 2>&1 && #{svn} add * 2>&1`
                status= $?.success? ? 0 : -1
                {:rescode=>status,:msg=>out}
            end

            def del_all(working_path)
                svn = `which svn`.strip
                out=`cd #{working_path} 2>&1 && touch "xxxxxxx" 2>&1 &&#{svn} rm --force *&& rm -rf * 2>&1`
                status= $?.success? ? 0 : -1
                {:rescode=>status,:msg=>out}
            end
 
            def checkout(svn_path,working_path,username,password)
                sleep 0.2
                svn = `which svn`.strip
                out=`#{svn} co #{svn_path} #{working_path} --username #{username} --password #{password} --no-auth-cache 2>&1`
                status= $?.success? ? 0 : -1
                {:rescode=>status,:msg=>out}
            end
        end
    end

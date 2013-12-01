    class Svn
        class << self
            def commit(working_path, message,username,password)
                svn = `which svn`.strip
                `cd #{working_path} && #{svn} commit -m "#{message}" --username #{username} --password #{password} --no-auth-cache`
                 $?.success?
            end
 
            def add_all(working_path)
                svn = `which svn`.strip
                `cd #{working_path} && #{svn} add *`
                $?.success?
            end

            def del_all(working_path)
                svn = `which svn`.strip
                `cd #{working_path} && touch "xxxxxxx" &&#{svn} rm --force *`
                $?.success?
            end
 
            def checkout(svn_path,working_path,username,password)
                svn = `which svn`.strip
                `#{svn} co #{svn_path} #{working_path} --username #{username} --password #{password} --no-auth-cache`
                $?.success?
            end
        end
    end

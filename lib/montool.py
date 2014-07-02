#!/home/opt/python2.7.5/bin/python
# -*- coding: utf-8 -*-

from datetime import datetime
from urllib2 import URLError
import fnmatch
import glob
import logging
import mimetypes
import optparse
import os
import socket
import subprocess
import sys
import time
import httplib
import urllib
import urllib2
import urlparse
import json
import re
reload(sys)
sys.setdefaultencoding('utf-8')
null_proxy_handler = urllib2.ProxyHandler({})
opener = urllib2.build_opener(null_proxy_handler)
urllib2.install_opener(opener)

DEFAULT_SERVER_HOST = "mt.noah.baidu.com"
DEFAULT_SERVER_PORT ="80"
DEFAULT_SVN_URL = "http://svn.noah.baidu.com/svn/conf/"
SCRIPT_VERSION = "3"
usages ='''
Monitor3.0 tool.
[notice] 
    *For create -c -t
    *For validation
        # validate current folder namespace(s), you must cd to the svn work copy folder(xxx)
        # xxx is the parent folder of namespace (../{namespace})
    *For block tool
        # block 
        # unblock
        # get block status 
        # get block log
    *For move -m/--move
    *For merge --merge
[argument]
    namespace 
    use magic:[*?[] pattern
    # Pattern Meaning
        *       matches everything
        ?       matches any single character
        [seq]   matches any character in seq
        [!seq]  matches any character not in seq
    
[eg.]
    montool.py -c noah.web.tc -t service    # create noah.web.tc namespace 
    montool.py -c noah.web.tc -t cluster    # create cluster.noah.web.tc namespace
    montool.py -c www.baidu.com -t domain   # create www.baidu.com namespace
    montool.py -v *                         # validate all the namespaces
    montool.py -v noah.web.tc,noah.web.jx   # validate the enum namespaces
    montool.py -v noah.web.*                # validate the mask namespaces
    montool.py -v noah.[web,monitor].*      # validate the noah.web.* && noah.monitor.*

    montool.py -m argus-test.noah.all       # move monitor 2.0 argus-test.noah.all to now
    montool.py -m baidu_op_oped_noah        # move monitor 2.0 baidu_op_oped_noah all to now
    montool.py --move_module baidu_op_oped_noah

    montool.py -b block.noah.all            # block service[block.noah.all] for 4h
    montool.py -b cq-oped-test.cq:instance  # block all instance alarm on cq-oped-test.cq for 4h
    montool.py -b cq-oped-test.cq:host      # block all host alarm on cq-oped-test.cq for 4h
    montool.py -b \033[0;40;32mcq-oped-test.cq\033[0m:\033[0;40;31mblock.noah.all:host:rule1\033[0m
                                            # block machine-rule[\033[0;40;32mmachine_name\033[0m:\033[0;40;31mrule_name\033[0m] for 4h
    montool.py -b \033[0;40;32m0.block.noah.all\033[0m:\033[0;40;31mblock.noah.all:instance:rule1\033[0m
                                            # block instance-rule[\033[0;40;32minstance_name\033[0m:\033[0;40;31mrule_name\033[0m] for 4h
    montool.py -b block.noah.all,0.block.noah.all,argus-test.noah.all:rule01,st01-oped-centos1.st01 
                                            # block service[block.noah.all],instance[0.block.noah.all],
                                            # rule[argus-test.noah.all:rule01],machine[st01-oped-centos1.st01] for 4h
    montool.py -b block.noah.all  -d 3600   # block block.noah.all for 1h

    montool.py -b noah.baidu.com  -d 3600   # block domain[noah.baidu.com] for 1h
    montool.py -b noah.baidu.com:ip:10.63.175.11  # block ip[10.63.175.11 at noah.baidu.com] for 1h

    montool.py -u block.noah.all            # un block block.noah.all
    montool.py -u block.noah.all,0.block.noah.all,argus-test.noah.all:rule01,st01-oped-centos1.st01
                                            # un block service[block.noah.all],instance[0.block.noah.all],
                                            # rule[argus-test.noah.all:rule01],machine[st01-oped-centos1.st01] 
    montool.py -s block.noah.all            # show the block status of block.noah.all
    montool.py -l block.noah.all            # show the block log of block.noah.all
    montool.py --merge=source_path --includes=mergepath1,mergepath2 --result_dir=result_path 
'''

def getNamespace( patterns,dirname ):
    value = []
    try:
        names = os.listdir(dirname)
    except os.error:
        logger_service.error(str(os.error))
        ErrorExit(os.error)
    for pattern in patterns:
	pattern = pattern.replace('/','')
        value += fnmatch.filter(names, pattern)
    return value

def readNamespace( dirname ):
    try:
        files = []
        values = []
        if os.path.isdir(dirname):  
            files = os.listdir(dirname)
        for filename in files:
            value = os.path.join(dirname,filename)
            if os.path.isfile(value):
                values.append ( (filename, value) )
    except os.error:
        logger_service.error(str(os.error))
        ErrorExit(os.error)
    return values

def ReadFileAsContent( file ):
    try:
      with open(file, 'rb') as f:
        filecontent = f.read()
    except Exception, e:
        logger_service.error(file + ' is read error,'+ str(e))
        print file + ' is read error,'+ e.message
        return ''
    return filecontent
def create( name, type, server):
    try:
        url = "http://%s/conf-manager/index.php?r=Script/GetFiles&name=%s&type=%s" % (server,name,type)
        http_service = HttpService()
        result,success = http_service.get(url)
        if not success:
            ErrorExit("url get fail!")
        result_json = json.loads(result)
        if result_json['success']:
            files = result_json['data']
        else:
            ErrorExit(result_json['message'])
        if type != 'service' and type != 'domain':
            newname = type + '.' + name
        else:
            newname = name
        if os.path.exists(newname):
            ErrorExit("folder "+newname+" is already exists")
        os.mkdir(newname)
        for filename in files:
            url = "http://%s/conf-manager/index.php?r=Script/Create&fileName=%s&type=%s" % (server,filename,type)
            http_service = HttpService()
            result,success = http_service.get(url)
            if not success:
                os.rmdir(newname)
                ErrorExit("url get fail!")
            else:
                newfile = re.sub('template',name,filename)
                newfile = os.path.join(newname,newfile)
                if isinstance( result, unicode ):
                    result = result.encode( 'utf-8' )
                f = open(newfile, 'wb')
                f.writelines(result)
                f.close()
        return True
    except Exception, e:
        logger_service.error(str(e))
        print e
        return ''

def validate( plat, prod, cata, name, values ):
    forms =[]
    files = []
    try:
	forms.append ( ('plat', plat ) )
        forms.append ( ('prod', prod ) )
        forms.append ( ( 'type', cata) )
        forms.append ( ( 'namespace', name) )
        for filename, path in values:
            files.append ( ( filename, filename, ReadFileAsContent(path) ) )
        content_type, body = EncodeMultipartFormData(forms, files)
        h = httplib.HTTPConnection(DEFAULT_SERVER_HOST , DEFAULT_SERVER_PORT)
        headers = { 'content-type': content_type,'User-Agent': 'INSERT USERAGENTNAME'}
        h.request('POST', "/conf-manager/index.php?r=Script/Validate", body, headers)
        res =  h.getresponse()
        return res.status, res.reason, res.read()
    except Exception, e:
        logger_service.error(str(e))
        print e
        return ''
def move( service_name ):
    try:
        url = "http://"+DEFAULT_SERVER_HOST+":"+DEFAULT_SERVER_PORT+"/conf-manager/index.php?r=NameSpace/ConvertByBns&service_name=%s" % (service_name)
        http_service = HttpService()
        result,success = http_service.get(url)
        if not success:
            ErrorExit("url get fail!")
        result_json = json.loads(result)
        if result_json['success']:
            files = result_json['data']
            count = result_json['count']
        else:
            ErrorExit(result_json['message'])
        dirname = service_name
        if os.path.exists(dirname):
            ErrorExit("error:folder "+dirname+" is already exists!")
        os.mkdir(dirname)
        print '=============%s=============' % (dirname)
        if len(files) > 0:
            for filename,content in files.iteritems():
                filename = os.path.join(dirname,filename)
                if isinstance( content, unicode ):
                    content = content.encode( 'utf-8' )
                f = open(filename, 'wb')
                f.writelines(content)
                f.close()
        print '监控项迁移概况'
        itemAll = count['item']['all']
        itemDone = count['item']['done']
        print ' %10s%10s%10s' % ('type','total','move')
        if len(itemAll) > 0:
            for key,num in itemAll.iteritems():
                print ' %10s%10s%10s' % (key,num,itemDone[key])
        print '监控策略迁移概况'
        ruleAll = count['rule']['all']
        ruleDone = count['rule']['done']
        if len(ruleAll) > 0:
            for key,num in ruleAll.iteritems():
                print ' %10s%10s%10s' % (key,num,ruleDone[key])
        return True
    except Exception, e:
        logger_service.error(str(e))
        print e
        return False

def moveByProd( service_name ):
    try:
        url = "http://yf-oped-dev02.yf01.baidu.com:8885/crius/metis-module/index.php?r=ModuleMonitor/ConvertByProd&path=%s" % (service_name)
        http_service = HttpService()
        result,success = http_service.get(url)
        if not success:
            ErrorExit("url get fail!")
        result_json = json.loads(result)
        if result_json['success']:
            services = result_json['data']
        else:
            ErrorExit(result_json['message'])
        for service in services:
            print "---------->start move %s" % (service)
            if os.path.exists(service):
                print "error:folder "+service+" is already exists!"
                continue
            else:
                url = "http://"+DEFAULT_SERVER_HOST+":"+DEFAULT_SERVER_PORT+"/conf-manager/index.php?r=NameSpace/ConvertByBns&service_name=%s" % (service)
                http_service = HttpService()
                result,success = http_service.get(url)
                if not success:
                    print "url get fail!"
                    continue
                result_json = json.loads(result)
                if result_json['success']:
                    files = result_json['data']
                    count = result_json['count']
                else:
                    print result_json['message']
                    continue
                os.mkdir(service)
                print '=============%s=============' % (service)
                if len(files) > 0:
                    for filename,content in files.iteritems():
                        filename = os.path.join(service,filename)
                        if isinstance( content, unicode ):
                            content = content.encode( 'utf-8' )
                        f = open(filename, 'wb')
                        f.writelines(content)
                        f.close()
                print '监控项迁移概况'
                itemAll = count['item']['all']
                itemDone = count['item']['done']
                print ' %10s%10s%10s' % ('type','total','move')
                if len(itemAll) > 0:
                    for key,num in itemAll.iteritems():
                        print ' %10s%10s%10s' % (key,num,itemDone[key])
                print '监控策略迁移概况'
                ruleAll = count['rule']['all']
                ruleDone = count['rule']['done']
                if len(ruleAll) > 0:
                    for key,num in ruleAll.iteritems():
                        print ' %10s%10s%10s' % (key,num,ruleDone[key])
                #time.sleep(1)
        return True
    except Exception, e:
        logger_service.error(str(e))
        print e
        return False

def moveDomain(domain):
    try:
        url = "http://yf-oped-dev02.yf01.baidu.com:8550/conf-manager/index.php?r=NameSpace/ConvertDomain&path=%s" % (domain)
        http_service = HttpService()
        result,success = http_service.get(url)
        if not success:
            ErrorExit("url get fail!")
        result_json = json.loads(result)
        if result_json['success']:
            files = result_json['data']
        else:
            ErrorExit(result_json['message'])
        for item in files:
            for domain,content in item.iteritems():
                dirname = domain
                if os.path.exists(dirname):
                    ErrorExit("error:folder "+dirname+" is already exists!")
                os.mkdir(dirname)
                print '=============%s=============' % (dirname)
                filename = os.path.join(dirname,'domain')
                if isinstance( content, unicode ):
                    content = content.encode( 'utf-8' )
                f = open(filename, 'wb')
                f.writelines(content)
                f.close()
        return True
    except Exception, e:
        logger_service.error(str(e))
        print e
        return False

def moveModule(paths):
    try:
        url = "http://yf-oped-dev02.yf01.baidu.com:8550/conf-manager/index.php?r=NameSpace/ConvertByModule&path=%s" % (paths)
        http_service = HttpService()
        result,success = http_service.get(url)
        if not success:
            ErrorExit("url get fail!")
        result_json = json.loads(result)
        if result_json['success']:
            files = result_json['data']
        else:
            ErrorExit(result_json['message'])
        for cluster,items in files.iteritems():
            dirname = cluster
            if os.path.exists(dirname):
                ErrorExit("error:folder "+dirname+" is already exists!")
            os.mkdir(dirname)
            print '=============%s=============' % (dirname)
            if len(items) > 0:
                for filename,content in items.iteritems():
                    filename = os.path.join(dirname,filename)
                    if isinstance( content, unicode ):
                        content = content.encode( 'utf-8' )
                    f = open(filename, 'wb')
                    f.writelines(content)
                    f.close()
        return True
    except Exception, e:
        logger_service.error(str(e))
        print e
        return False

def merge( source,merges,result_dir ):
    try:
        forms =[]
        files = []
        mergeList = []
        if source.endswith('/'):
            namespace=source.split('/')[-2]
        else:
            namespace=source.split('/')[-1] 
        for f in os.listdir(source):
            if not f.endswith('.tmpl') and not f.endswith('readme.txt'):
                file=os.path.join(source,f)
                if os.path.isfile(file):
                    filename=namespace+'#'+f
                    files.append ( ( filename, filename, ReadFileAsContent(file) ) )
        forms.append ( ('namespace', namespace ) )
        for i in merges.split(','):
            if source.endswith('/'):
                merge=i.split('/')[-2]
            else:
                merge=i.split('/')[-1]
            for f in os.listdir(i):
                if not f.endswith('.tmpl') and not f.endswith('readme.txt'):
                    file=os.path.join(i,f)
                    if os.path.isfile(file):
                        filename=merge+'#'+f
                        files.append ( ( filename, filename, ReadFileAsContent(file) ) )
            mergeList.append(merge)
        forms.append ( ('merges', ','.join(mergeList) ) )
        content_type, body = EncodeMultipartFormData(forms, files)
        h = httplib.HTTPConnection(DEFAULT_SERVER_HOST , DEFAULT_SERVER_PORT)
        headers = { 'content-type': content_type,'User-Agent': 'INSERT USERAGENTNAME'}
        h.request('POST', "/conf-manager/index.php?r=Script/Merge", body, headers)
        res =  h.getresponse()
        if res.status == 200:
            result_json = json.loads(res.read())
            if result_json['success']:
                files = result_json['data']
            else:
                ErrorExit(result_json['message'])
            if os.path.exists(result_dir):
                ErrorExit("error:folder "+result_dir+" is already exists!")
            os.mkdir(result_dir)
            print 'create %s success !' % (result_dir)
            for filename,content in files.iteritems():
                filename = os.path.join(result_dir,filename)
                if isinstance( content, unicode ):
                    content = content.encode( 'utf-8' )
                f = open(filename, 'wb')
                f.writelines(content)
                print 'create %s success !' % (filename)
                f.close()  
            return True 
        else:
            ErrorExit("url get fail!")
    except Exception, e:
        logger_service.error(str(e))
        print e
        return False

class HttpService():
    def post(self,url,params):
        return self.__service(url, params)
    def get(self,url):
        return self.__service(url)
    def __service(self,url,params=None,timeout=50):
        old_timeout = socket.getdefaulttimeout()
        socket.setdefaulttimeout( timeout )
        try:
            #POST
            if params:
                request = urllib2.Request( url, urllib.urlencode(params) )
            #GET
            else:
                request = urllib2.Request( url )
            request.add_header( 'Accept-Language', 'zh-cn' )
            response = urllib2.urlopen( request )
            content = response.read()
            if response.code==200:
                return content,True
            return content,False
        except Exception,ex:
            logger_service.error(str(ex))
            return str(ex),False
        finally:
            if 'response' in dir():
                response.close()
            socket.setdefaulttimeout( old_timeout )

class LoggerService():
    def __init__(self,log_level):
        user_folder = os.path.expanduser('~')
        log_folder = user_folder+'/.monitorlog'
        #check 
        if not os.path.exists(log_folder):
            os.makedirs(log_folder)
        current_time= datetime.now()
        log_filename = log_folder+'/monitor.'+current_time.strftime('%Y-%m-%d')+'.log'
        self.log_filename =log_filename
        self.log_level = log_level
        self.init_logger()
    def init_logger(self):
        logging.basicConfig(level=self.log_level,
                    format='%(asctime)s %(levelname)s %(message)s',
                    filename=self.log_filename,
                    filemode='a')
        logger = logging.getLogger()
        self.logger = logger
    def info(self,info):
        self.logger.info(info)
    def debug(self,debug):
        self.logger.debug(debug)
    def warn(self,warn):
        self.logger.warning(warn)
    def error(self,error):
        self.logger.error(error)

def isNewVersion( script_verison, server ):
  url = "http://%s/conf-manager/index.php?r=Script/CheckVersion&version=%s" % (server,script_verison)
  http_service = HttpService()
  result,success = http_service.get(url)
  if not success:
    print "[warning]version check fail!"
    return True
  if result == 'true':
    return True
  else:
    return False

def getSvnInfo():
    try:
        info, returncode = RunShellWithReturnCode( ["svn", "info"] )
        if returncode == 0:
            for line in info.splitlines():
                if line.startswith( "URL: " ):
                  url = line.split()[1]
                  if url.startswith(DEFAULT_SVN_URL):
                    infos = url.split(DEFAULT_SVN_URL)[1]
                    plat,prod,cata = infos.split("/")
                    return plat,prod,cata
                  else:
                    logger_service.error( "svn info is wrong")
                    ErrorExit( "svn info is wrong")
        else:
            logger_service.error( "Can't find URL in output from svn info")
            ErrorExit( "Can't find URL in output from svn info,please check in the ../{namespace} svn work copy")
    except:
      logger_service.error( "Can't find URL in output from svn info")
      ErrorExit( "Can't find URL in output from svn info,please check in the ../{namespace} svn work copy")
def EncodeMultipartFormData( fields, files ):
    """Encode form fields for multipart/form-data.

  Args:
    fields: A sequence of (name, value) elements for regular form fields.
    files: A sequence of (name, filename, value) elements for data to be
           uploaded as files.
  Returns:
    (content_type, body) ready for httplib.HTTP instance.

  Source:
    http://aspn.activestate.com/ASPN/Cookbook/Python/Recipe/146306
  """
    BOUNDARY = '-M-A-G-I-C---B-O-U-N-D-A-R-Y-'
    CRLF = '\r\n'
    lines = []
    for ( key, value ) in fields:
        lines.append( '--' + BOUNDARY )
        lines.append( 'Content-Disposition: form-data; name="%s"' % key )
        lines.append( '' )
        if isinstance( value, unicode ):
            value = value.encode( 'utf-8' )
        lines.append( value )
    for ( key, filename, value ) in files:
        lines.append( '--' + BOUNDARY )
        lines.append( 'Content-Disposition: form-data; name="%s"; filename="%s"' %
                 ( key, filename ) )
        lines.append( 'Content-Type: %s' % GetContentType( filename ) )
        lines.append( '' )
        if isinstance( value, unicode ):
            value = value.encode( 'utf-8' )
        lines.append( value )
    lines.append( '--' + BOUNDARY + '--' )
    lines.append( '' )
    body = CRLF.join( lines )
    content_type = 'multipart/form-data; boundary=%s' % BOUNDARY
    return content_type, body

def GetContentType( filename ):
  """Helper to guess the content-type from the filename."""
  return mimetypes.guess_type( filename )[0] or 'application/octet-stream'

parser = optparse.OptionParser( 
    usage = usages,
    epilog = "For more help, please visit: http://devops.baidu.com/new/argus/montool.md" )
parser.add_option( "-c", "--create", action = "store",
                  dest = "name", default = False,
                  help = "create a new namespace" )
parser.add_option( "-t", "--type", action = "store",
                  dest = "type", default = False,
                  help = "for create ,the namespace type " )
parser.add_option( "-v", "--validate", action = "store",
                  dest = "ns", default = False,
                  help = "validate the svn work copy namespaces" )
parser.add_option( "-b", "--block", action = "store",
                  dest = "blocknames", default = False,
                  help = "block name" )
parser.add_option( "-d", "--disabletime", action = "store",
                  dest = "disabletime", default = False,
                  help = "block disable time" )
parser.add_option( "-u", "--unblock", action = "store",
                  dest = "unblocknames", default = False,
                  help = "unblock name" )
parser.add_option( "-s", "--blockstatus", action = "store",
                  dest = "statusname", default = False,
                  help = "get block status" )
parser.add_option( "-l", "--blocklog", action = "store",
                  dest = "logname", default = False,
                  help = "get block log" )
parser.add_option( "-r", "--rules", action = "store",
                  dest = "rules", default = False,
                  help = "get rule list" )
parser.add_option( "-m", "--move", action = "store",
                  dest = "move", default = False,
                  help = "move monitor 2.0 to argus" )
parser.add_option( "--merge", action = "store",
                  dest = "merge", default = False,
                  help = "merge soure" )
parser.add_option( "--includes", action = "store",
                  dest = "includes", default = False,
                  help = "includes" )
parser.add_option( "--result_dir", action = "store",
                  dest = "result_dir", default = False,
                  help = "result_dir" )
parser.add_option( "--move_domain", action = "store",
                  dest = "move_domain", default = False,
                  help = "move_domain" )
parser.add_option( "--move_module", action = "store",
                  dest = "move_module", default = False,
                  help = "move_module" )
parser.add_option( "--move_diff", action = "store",
                  dest = "move_diff", default = False,
                  help = "move_diff" )

# Use a shell for subcommands on Windows to get a PATH search.
use_shell = sys.platform.startswith( "win" )   

def RunShellWithReturnCode( command, print_output = False,
                           universal_newlines = True,
                           env = os.environ ):
    """Executes a command and returns the output from stdout and the return code.

  Args:
    command: Command to execute.
    print_output: If True, the output is printed to stdout.
                  If False, both stdout and stderr are ignored.
    universal_newlines: Use universal_newlines flag (default: True).

  Returns:
    Tuple (output, return code)
  """
    logger_service.info( "Running %s"%command )
    p = subprocess.Popen( command, stdout = subprocess.PIPE, stderr = subprocess.PIPE,
                         shell = use_shell, universal_newlines = universal_newlines,
                         env = env )
    
    if print_output:
        output_array = []
        while True:
            line = p.stdout.readline()
            if not line:
                break
            print line.strip( "\n" )
            output_array.append( line )
        output = "".join( output_array )
    else:
        output = p.stdout.read()
    p.wait()
    errout = p.stderr.read()
    index = errout.find( "E155036" )
    if index != -1:
        p.returncode = 5
    if errout:
        logger_service.error(errout)
    p.stdout.close()
    p.stderr.close()
    return output, p.returncode
def StatusUpdate( msg ):
    """Print a status message to stdout.

  If 'verbosity' is greater than 0, print the message.

  Args:
    msg: The string to print.
  """
    if verbosity > 0:
        print msg

def ErrorExit( msg ):
  """Print an error message to stderr and exit."""
  print >> sys.stderr, msg
  sys.exit( 1 )
def checkVersion():
    if SCRIPT_VERSION:
        version = SCRIPT_VERSION
        isNewVer = isNewVersion( version, DEFAULT_SERVER_HOST + ":" + DEFAULT_SERVER_PORT )
        if not isNewVer:
            logger_service.warn("Your montool.py isn't the lastest version,please update it from http://dl.noah.baidu.com/argus/montool.py\nif continue,May be it will make the operation fail")
            print "WARNNING:\nYour montool.py isn't the lastest version,please update it from http://dl.noah.baidu.com/argus/montool.py\nif continue,May be it will make the operation fail."
            prompt = "Are you sure to continue?(y/n) :"
            answer = raw_input( prompt ).strip()
            if answer != "y":
                ErrorExit( "User aborted" )

global logger_service 
logger_service = LoggerService(logging.WARNING)

def main():

  checkVersion()
  if len(sys.argv) <2:
    print usages
    sys.exit(2)
  options, args = parser.parse_args( sys.argv[1:] )
  if options.name:
    if options.type:
        res = create(options.name, options.type, DEFAULT_SERVER_HOST+":"+DEFAULT_SERVER_PORT)
        if res:
            print "create success!"
        else:
            print "create fail!"
  if options.ns:
    dirname = os.getcwd()
    plat,prod,cata = getSvnInfo()
    namespaces = getNamespace(sys.argv[2:], dirname)
    for namespace in namespaces:
        value = readNamespace(os.path.join(dirname, namespace))
        if value:
            print "["+namespace + "] is checking.........",
            code, mesg, info = validate(plat, prod, cata, namespace, value)
            if code == 200:
                print "-->result : " + info
            else:
                print "["+namespace + "] check error " + mesg
        else:
            print """[%s] is empty"""%namespace 
        time.sleep(0.5)
  elif options.move:
    service_name = options.move
    if '_' in service_name:
        res = moveByProd(service_name)
    else:
        res = move(service_name)
    if res:
        print "finish!"
    else:
        print 'move fails'
  elif options.merge:
    res = merge(options.merge,options.includes,options.result_dir)
    if res:
        print "merge success,please check %s"%options.result_dir
    else:
        print 'merge fails'
  elif options.move_domain:
    path = options.move_domain
    res = moveDomain(path)
    if res:
        print "finish!"
    else:
        print 'move fails'
  elif options.move_module:
    path = options.move_module
    res = moveModule(path)
    if res:
        print "finish!"
    else:
        print 'move fails'
  elif options.move_diff:
    reqUrl = "http://yf-oped-dev02.yf01.baidu.com:8885/crius/metis-module/index.php?r=ModuleMonitor/GetDiff"
    http_service = HttpService()
    result,success = http_service.get(reqUrl+"&service="+options.move_diff)
    if success:
        result_json = json.loads(result)
        if result_json['success']:
            data = result_json['data']
            count = max(data['item']['old_count'],data['item']['new_count'])
            print  '%s%s' % ("old_item("+str(data['item']['old_count'])+")".ljust(30),"new_item("+str(data['item']['new_count'])+")".ljust(30))
            for i in range(0,count):
                if i > data['item']['old_count']-1:
                    old='NULL'
                else:
                    old=data['item']['old'][i]+" "
                if i> data['item']['new_count']-1:
                    new='NULL'
                else:
                    new=data['item']['new'][i]
                print   '%s%s' % (old.ljust(40),new.ljust(40))
            print '============================BOUNDARY=============================='
            print '%s%s' % ("old_rule("+str(data['rule']['old_count'])+")".ljust(30),"new_rule("+str(data['rule']['new_count'])+")".ljust(30))
            count = max(data['rule']['old_count'],data['rule']['new_count'])
            for i in range(0,count):
                if i>data['rule']['old_count']-1:
                    old='NULL'
                else:
                    old=data['rule']['old'][i]+" "
                if i> data['rule']['new_count']-1:
                    new='NULL'
                else:
                    new=data['rule']['new'][i]
                print '%s%s' % (old.ljust(40),new.ljust(40))    
        else:
            print result_json['message'].encode('utf-8')
            
    else:
        print result
  elif options.blocknames:
    #block name
    disabletime = 4*60*60 #default block 4h
    if options.disabletime:
        disabletime = int(options.disabletime)    
    disabletime = time.localtime(disabletime+time.time())
    disabletime = time.strftime('%Y-%m-%d %X',disabletime)
    reqUrl = "http://"+DEFAULT_SERVER_HOST+":"+DEFAULT_SERVER_PORT+"/block/index.php?r=BlockService/blockAll"
    http_service = HttpService()    
    disabletime = disabletime.replace(' ','%20')
    result,success = http_service.get(reqUrl+"&info="+options.blocknames+"&disableTime="+disabletime+"&comment=[MTool]")
    if success:
        result_json = json.loads(result)
        if result_json['success']:
            print 'OK'
        else:
            print result_json['message'].encode('utf-8')
    else:
        print result
  elif options.unblocknames:
    #unblock
    reqUrl = "http://"+DEFAULT_SERVER_HOST+":"+DEFAULT_SERVER_PORT+"/block/index.php?r=BlockService/unblockAll"
    http_service = HttpService()
    result,success = http_service.get(reqUrl+"&info="+options.unblocknames+"&comment=[MTool]")
    if success:
        result_json = json.loads(result)
        if result_json['success']:
            print 'OK'
        else:
            print result_json['message'].encode('utf-8')
    else:
        print result
  elif options.statusname:
    reqUrl = "http://"+DEFAULT_SERVER_HOST+":"+DEFAULT_SERVER_PORT+"/block/index.php?r=BlockService/getblockstatus"
    http_service = HttpService()
    result,success = http_service.get(reqUrl+"&name="+options.statusname)
    if success:
        result_json = json.loads(result)
        if result_json['success']:
            if result_json['data']['block'] == 1:
                print options.statusname+'\tblocked\t'+result_json['data']['disableTime']+'\tdimension['+result_json['data']['dimension'].encode('utf-8')+']'
            else:
                print options.statusname+'\tunblocked'
        else:
            print result_json['message'].encode('utf-8')
    else:
        print result
  elif options.logname:
    reqUrl = "http://"+DEFAULT_SERVER_HOST+":"+DEFAULT_SERVER_PORT+"/block/index.php?r=BlockService/getblocklog&perPage=1000"
    http_service = HttpService()
    result,success = http_service.get(reqUrl+"&name="+options.logname)
    if success:
        result_json = json.loads(result)
        if result_json['success']:
            if len(result_json['data']['list']) > 0:
                for log in result_json['data']['list']:
                    msg = log['op_time']+'\t'+log['ip']+'\t'
                    if log['action_type'] == '1':
                        msg += 'add'
                    else:
                        msg += 'del'
                    print msg+'\t'+log['comment'].encode('utf-8')
            else:
                print 'no block log'
        else:
            print result_json['message'].encode('utf-8')
    else:
        print result
  elif options.rules:
    reqUrl = "http://"+DEFAULT_SERVER_HOST+":"+DEFAULT_SERVER_PORT+"/block/index.php?r=BlockService/getrulelist"
    http_service = HttpService()
    result,success = http_service.get(reqUrl+"&name="+options.rules)
    if success:
        result_json = json.loads(result)
        if result_json['success']:
            if len(result_json['data']) > 0:
                for rule in result_json['data']:
                    if rule['block']:
                        print rule['name'].encode('utf-8')+'\tblocked\tdisableTime['+rule['disableTime']+']\tdimension['+rule['dimension'].encode('utf-8')+']'
                    else:
                        print rule['name'].encode('utf-8')+'\tunblocked'
            else:
                print 'no rule'
        else:
            print result_json['message'].encode('utf-8')
    else:
        print result
if __name__ == "__main__":
  try:
    main()
  except KeyboardInterrupt:
    StatusUpdate( "Interrupted." )
    sys.exit( 1 )

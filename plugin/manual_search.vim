"=============================================================================
"
"     FileName: manual_search.vim
"         Desc: 开发文档搜索
"               需要先安装 w3m.vim
"
"       Author: LongChangjin
"        Email: admin@longchangjin.cn
"
"      Created: 2014-06-06
"
"=============================================================================

if !exists("g:php_manual_dir_path")
  " http://ar2.php.net/download-docs.php
  let g:php_manual_dir_path = $HOME . "/Book/Refernce/php/php-chunked-xhtml/"
endif

if !exists("g:php_symfony2_manual_dir_path")
  " http://symfony.com/doc/current/index.html
  let g:php_symfony2_manual_dir_path = $HOME . "/Book/Refernce/php/api.symfony.com/2.4/"
endif

if !exists("g:php_symfony2_api_manual_dir_path")
  " http://api.symfony.com/2.4/index.html
  let g:php_symfony2_api_manual_dir_path = $HOME . "/Book/Refernce/php/api.symfony.com/2.4/"
endif

if !exists("g:python2_manual_dir_path")
  " https://docs.python.org/2/
  let g:python2_manual_dir_path = $HOME . "/Book/Refernce/python-2.7.4-docs-html/"
endif

if !exists("g:python3_manual_dir_path")
  " https://docs.python.org/3/
  let g:python3_manual_dir_path = $HOME . "/Book/Refernce/python-3.3.3-docs-html/"
endif

if !exists("g:ruby_core_manual_dir_path")
  " http://www.ruby-doc.org/downloads/
  let g:ruby_core_manual_dir_path = $HOME . "/Book/Refernce/Ruby/ruby_2_1_1_core/"
endif

if !exists("g:ruby_stdlib_manual_dir_path")
  " http://www.ruby-doc.org/downloads/
  let g:ruby_stdlib_manual_dir_path = $HOME . "/Book/Refernce/Ruby/ruby_2_1_1_stdlib/"
endif

function! W3M_PHPManual()
  execute "W3mTab local " . g:php_manual_dir_path . "index.html"
endfunction

function! W3M_PHPSymfonyApi()
  execute "W3mTab local " . g:php_symfony2_api_manual_dir_path . "index.html"
endfunction

function! W3M_Python2Docs()
  execute "W3mTab local " . g:python2_manual_dir_path . "index.html"
endfunction

function! W3M_Python3Docs()
  execute "W3mTab local " . g:python3_manual_dir_path . "index.html"
endfunction

function! W3M_RubyCore()
  execute "W3mTab local " . g:ruby_core_manual_dir_path . "index.html"
endfunction

function! W3M_RubyStdlib()
  execute "W3mTab local " . g:ruby_stdlib_manual_dir_path . "index.html"
endfunction

command! -nargs=0 PHPManual :call W3M_PHPManual()
command! -nargs=0 PHPSymfonyApi :call W3M_PHPSymfonyApi()
command! -nargs=0 Python2Docs :call W3M_Python2Docs()
command! -nargs=0 Python3Docs :call W3M_Python3Docs()
command! -nargs=0 RubyCore :call W3M_RubyCore()
command! -nargs=0 RubyStdlib :call W3M_RubyStdlib()


" http://vimdoc.sourceforge.net/htmldoc/if_ruby.html
if !has('ruby')
  echo "Error: Required vim ruby"
  finish
endif

" 创建缓存
ruby <<_EOF_
  require "json"
  $manual_search_w3m_buffer_num = nil
  def gen_cache
    data = {
      "function" => [],
      "class" => [],
    }
    path = VIM::evaluate("g:php_manual_dir_path")
    p path
    Dir["#{path}/function*.html"].each do |f|
      name = File::basename f
      data["function"].push name
    end
    Dir["#{path}/class*.html"].each do |f|
      name = File::basename f
      data["class"].push name
    end
    File.write "#{Dir.home}/.vim_php_manual_cache", JSON::dump(data)
    data
  end
  def get_cache
    begin
      data = JSON::load File.read "#{Dir.home}/.vim_php_manual_cache"
    rescue
      data = nil
    end
    if !data then
      data = gen_cache
    end
    data
  end
_EOF_

" 使用w3m打开文档文件
function! s:OpenUrl()
"ruby <<_EOF_
"  uri = VIM::evaluate("b:manual_path") + $curbuf[$curbuf.line_number]
"  p "#{$curbuf.number} #{$curbuf.name}"
"  if $manual_search_w3m_buffer_num && VIM::Buffer[$manual_search_w3m_buffer_num] then
"    VIM::Buffer[$manual_search_w3m_buffer_num].command("W3m #{uri}")
"  else
"    $curbuf.command("W3mTab #{uri}")
"    p "#{$curbuf.number} #{$curbuf.name}"
"  end
"_EOF_
  let uri = getline('.')
  execute "W3mTab local " . b:manual_path . uri
endfunction

" 按键绑定
function! s:MapKeys()
    nnoremap <script> <silent> <buffer> <CR>          :call <SID>OpenUrl()<CR>
    nnoremap <script> <silent> <buffer> o             :call <SID>OpenUrl()<CR>
    nnoremap <script> <silent> <buffer> q             :bd<CR>
    for k in ["G", "n", "N", "L", "M", "H"]
        execute "nnoremap <buffer> <silent>" k ":keepjumps normal!" k."<CR>"
    endfor
endfunction

" PHP文档搜索
function! s:ManualPHPCache()
ruby <<_EOF_
  gen_cache
_EOF_
endfunction

function! s:ManualPHPSearch(args)
  topleft new
  setlocal buftype=nofile
  let b:manual_path = g:php_manual_dir_path

ruby <<_EOF_
  data = get_cache
  if data
    i = 0
    key = VIM::evaluate "a:args"
    key.downcase!
    key.gsub!('-', '_')
    data.each do |k, v|
      v.each do |f|
        if f.gsub('-', '_').include? key then
          if i == 0 then
            $curbuf[1] = f
            i = i + 1
          else
            $curbuf.append $curbuf.line_number-1, f
          end
        end
      end
    end
  end
_EOF_

  call s:MapKeys()
  setlocal buftype=nofile readonly nomodifiable nowrap
  setlocal bufhidden=hide
endfunction

command! -nargs=1 -range ManualPHPSearch :call s:ManualPHPSearch(<f-args>)
command! -nargs=0 ManualPHPCache :call s:ManualPHPCache()


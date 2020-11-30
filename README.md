# vim-fz

Ultra Fast Fuzzy finder for Vim8 and NeoVim.

But very very experimental!

![Fz](https://raw.githubusercontent.com/mattn/vim-fz/master/screenshot.gif)

## Usage

```
:Fz
```

Or type `,f`

## APIs

### type: cmd

```vim
nnoremap <C-p> :execute system('git rev-parse --is-inside-work-tree') =~ 'true'
      \ ? fz#run({ 'type': 'cmd', 'cmd': 'git ls-files' })
      \ : 'Fz'<CR>
```

### type: list

```vim
command! FzColors call fz#run({
    \ 'type': 'list',
    \ 'list': uniq(map(split(globpath(&rtp, "colors/*.vim"), "\n"), "substitute(fnamemodify(v:val, ':t'), '\\..\\{-}$', '', '')")),
    \ 'accept': {result->execute('colorscheme ' . result['items'][0])},
    \ })
```

## Requirements

* [gof](https://github.com/mattn/gof)
* vim8 or neovim

## Installation

```
$ go get github.com/mattn/gof
```

*  [Pathogen](https://github.com/tpope/vim-pathogen)
    * `git clone https://github.com/mattn/vim-fz.git ~/.vim/bundle/vim-fz`
*  [vim-plug](https://github.com/junegunn/vim-plug)
    * `Plug 'mattn/vim-fz'`
*  [Vim packages](http://vimhelp.appspot.com/repeat.txt.html#packages)
    * `git clone https://github.com/mattn/vim-fz.git ~/.vim/pack/plugins/start/vim-fz`

## License

MIT

## Author

Yasuhiro Matsumoto (a.k.a. mattn)

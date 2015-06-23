
var trie_built = false
var hiragana_trie = {}


/*
 * Mapping between wāpuro rōmaji and hiragana
 * 'a': 'あ'  replaces 'a' with 'あ'
 * 'nk': ['ん', 'k'] replaces 'nk' with 'ん' and adds 'k' for further parsing (e.g. nka → んka → んか)
ゑゎ
 */
var hiragana_map = {
    '゛゛': '゜',

    'う゛': 'ぅ',
    'か゛': 'が', 'き゛': 'ぎ', 'く゛': 'ぐ', 'け゛': 'げ', 'こ゛': 'ご',
    'さ゛': 'ざ', 'し゛': 'じ', 'す゛': 'ず', 'せ゛': 'ぜ', 'そ゛': 'ぞ',
    'た゛': 'だ', 'ち゛': 'ぢ', 'つ゛': 'っ', 'て゛': 'で', 'と゛': 'ど',
    'は゛': 'ば', 'ひ゛': 'び', 'ふ゛': 'ぶ', 'へ゛': 'べ', 'ほ゛': 'ぼ',
    'は゜': 'ぱ', 'ひ゜': 'ぴ', 'ふ゜': 'ぷ', 'へ゜': 'ぺ', 'ほ゜': 'ぽ',
    'ば゛': 'ぱ', 'び゛': 'ぴ', 'ぶ゛': 'ぷ', 'べ゛': 'ぺ', 'ぼ゛': 'ぽ',

    'あ゛': 'ぁ', 'い゛': 'ぃ', 'ぅ゛': 'ゔ', 'え゛': 'ぇ', 'お゛': 'ぉ',
    'ぁ゛': 'あ', 'ぃ゛': 'い', 'ゔ゛': 'う', 'ぇ゛': 'え', 'ぉ゛': 'お',
    'が゛': 'か', 'ぎ゛': 'き', 'ぐ゛': 'く', 'げ゛': 'け', 'ご゛': 'こ',
    'ざ゛': 'さ', 'じ゛': 'し', 'ず゛': 'す', 'ぜ゛': 'せ', 'ぞ゛': 'そ',
    'だ゛': 'た', 'ぢ゛': 'ち', 'っ゛': 'づ', 'で゛': 'て', 'ど゛': 'と',
    'づ゛': 'つ',

    'な゛': 'な', 'に゛': 'に', 'ぬ゛': 'ぬ', 'ね゛': 'ね', 'の゛': 'の',
    'ぱ゛': 'は', 'ぴ゛': 'ひ', 'ぷ゛': 'ふ', 'ぺ゛': 'へ', 'ぽ゛': 'ほ',
    'ま゛': 'ま', 'み゛': 'み', 'む゛': 'む', 'め゛': 'め', 'も゛': 'も',
    'や゛': 'ゃ', 'ゆ゛': 'ゅ', 'よ゛': 'ょ',
    'ゃ゛': 'や', 'ゅ゛': 'ゆ', 'ょ゛': 'よ',
    'ら゛': 'ら', 'り゛': 'り', 'る゛': 'る', 'れ゛': 'れ', 'ろ゛': 'ろ',
    'わ゛': 'わ', 'を゛': 'を', 'ん゛': 'ん',
    'ー゛': '―', '―゛': '～', '～゛': 'ー',

    'な゜': 'な', 'に゜': 'に', 'ぬ゜': 'ぬ', 'ね゜': 'ね', 'の゜': 'の',
    'ぱ゜': 'は', 'ぴ゜': 'ひ', 'ぷ゜': 'ふ', 'ぺ゜': 'へ', 'ぽ゜': 'ほ',
    'ま゜': 'ま', 'み゜': 'み', 'む゜': 'む', 'め゜': 'め', 'も゜': 'も',
    'や゜': 'ゃ', 'ゆ゜': 'ゅ', 'よ゜': 'ょ',
    'ゃ゜': 'や', 'ゅ゜': 'ゆ', 'ょ゜': 'よ',
    'ら゜': 'ら', 'り゜': 'り', 'る゜': 'る', 'れ゜': 'れ', 'ろ゜': 'ろ',
    'わ゜': 'わ', 'を゜': 'を', 'ん゜': 'ん',
    'ー゜': '―', '―゜': '～', '～゜': 'ー'
}



function build_hiragana_trie() {
    hiragana_trie = {}
    for (var k in hiragana_map) {
        var cur = hiragana_trie
        Array.prototype.forEach.call(k, function(c) {
            if (!(c in cur)) {
                cur[c] = {}
            }
            cur = cur[c]
        })
        cur['end'] = hiragana_map[k]
    }
    
    trie_built = true
}

function parse_char(str) {
    var pos = 0
    var buff = []
    str = str.split('')
    
    while (pos < str.length) {
        var cur = hiragana_trie
        var end = null
        var end_i = -1
        for (var i = pos; i < str.length && str[i] in cur; i++) {
            cur = cur[str[i]]
            if ('end' in cur) {
                end = cur['end']
                end_i = i
                break
            }
        }
        if (end != null) {
            pos = end_i + 1 // skip to after current segment
            if (Array.isArray(end)) {
                // add second element to the current position in str
                Array.prototype.splice.bind(str, pos, 0).apply(null, end[1].split(''))
                buff.push(end[0])
            } else {
                buff.push(end)
            }
        } else {
            // add first character as-is if no match available and skip to next
            buff.push(str[pos])
            pos++
        }
    }
    
    return buff.join('')
}

function hiragana_to_katakana(str) {
    return str.replace(/./g, function(c) {
        var cc = c.charCodeAt()
        if (cc >= 0x3041 && cc <= 0x3094) {
            return String.fromCharCode(cc + 96)
        } else {
            return c
        }
    })
}

function alphabet_to_uppercase(str) {
    return str.replace(/./g, function(c) {
        var cc = c.charCodeAt()
        if (cc >= 0x0061 && cc <= 0x007A) {
            return String.fromCharCode(cc - 32)
        } else {
            return c
        }
    })
}

# Issue #41: repeated spaces turn into repeated dashes

Reported by a user:

    slugify('Hello   World')     // 'hello---world', expected 'hello-world'
    slugify('Rock - Paper')      // 'rock---paper',  expected 'rock-paper'

Anything that produces more than one separator in a row should collapse to a
single dash.

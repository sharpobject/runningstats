runningstats
============

Streaming/distributed central moments

So like maybe you have a lot of data, and you want to know the central moments or just the skewness or something, it would suck to have to put it all in one place or iterate through it multiple times. This thing lets you calculate the central moments and stuff in one pass, maybe even dividing your dataset across many machines and adding together the results from each machine very quickly. Nice!

This code is based on this paper:
http://prod.sandia.gov/techlib/access-control.cgi/2008/086212.pdf

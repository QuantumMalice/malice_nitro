return {
    ['install'] = {
        label = locale('progress.install'),
        duration = 10000,
        position = 'bottom',
        useWhileDead = false,
        canCancel = true,
        disable = {
            car = false,
            move = true,
            combat = true,
            mouse = false,
        },
        anim = {
            dict = 'missheistdockssetup1clipboard@idle_a',
            clip = 'idle_a'
        },
    },
    ['uninstall'] = {
        label = locale('progress.uninstall'),
        duration = 10000,
        position = 'bottom',
        useWhileDead = false,
        canCancel = true,
        disable = {
            car = false,
            move = true,
            combat = true,
            mouse = false,
        },
        anim = {
            dict = 'missheistdockssetup1clipboard@idle_a',
            clip = 'idle_a'
        },
    }
}
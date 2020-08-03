

 Quasar.iconSet.set(Quasar.iconSet.themify)

const home = httpVueLoader('app/index.vue')
const dashboard = httpVueLoader('app/pages/dashboard.vue')
const databases = httpVueLoader('app/pages/databases.vue')
const objects = httpVueLoader('app/pages/objects.vue')
const relations = httpVueLoader('app/pages/relations.vue')
const settings = httpVueLoader('app/pages/settings.vue')
const notFound = httpVueLoader('app/pages/notFound.vue')


const routes = [
    {
        path: '/',
        redirect: '/home'
    },
    { 
        path: '/home',
        name: 'home',
        component: home,
        children: [
            {path: 'dashboard', component: dashboard, name: 'Dashboard'},
            {path: 'databases', component: databases, name: 'Databases'},
            {path: 'objects', component: objects, name: 'Objects'},
            {path: 'relations', component: relations, name: 'Relations', redirect: 'notFound'},
            {path: 'settings', component: settings, name: 'Settings', redirect: 'notFound'},
            {path: '*', component: notFound, name: 'notFound' }
        ],
        redirect: '/home/dashboard'
    },
    { path: '*', component: notFound, name: 'NotFound' }
]

const router = new VueRouter({
    routes // short for `routes: routes`
})

router.beforeEach((to, from, next) => {
    console.log('from', from.fullPath, 'going to', to.fullPath)
    if (from.fullPath === to.fullPath) {
        return
    }
    if (to.query.wait) {
        setTimeout(() => next(), 100)
    } else if (to.query.redirect) {
        next(to.query.redirect)
    } else if (to.query.abort) {
        next(false)
    } else {
        next()
    }
})

const app = new Vue({
    router
}).$mount('#app')
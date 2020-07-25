

 Quasar.iconSet.set(Quasar.iconSet.themify)

const home = httpVueLoader('app/index.vue')
const dashboard = httpVueLoader('app/pages/dashboard.vue')
const Bar = { template: '<div>Bar</div>' }

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
            {path: 'dashboard', component: dashboard},
        ]
    },
]

const router = new VueRouter({
    routes // short for `routes: routes`
})

const app = new Vue({
    router
}).$mount('#app')
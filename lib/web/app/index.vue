<template>
  <div>
    <q-layout view="hHh Lpr lff" class="bg-grey-3" >
      <q-header elevated>
        <div class="bg-pink-9 text-white">
            <q-toolbar>
                <q-btn  flat dense @click="drawer = !drawer" icon="ti-menu" class="q-ml-sm q-pa-sm" />
                <q-space />
            </q-toolbar>
            <q-toolbar inset>
              <q-avatar>
                <img src="assets/img/fos.svg">
              </q-avatar>
              <q-toolbar-title><strong>Flutter ORM Sugar</strong> Library</q-toolbar-title>
            </q-toolbar>
        </div>
      </q-header>
      <!-- this is where the Pages are injected -->
      <q-page-container style="background-image: url(assets/img/wallpaper.jpg);background-size: contain;">
        <router-view></router-view>
      </q-page-container>
      <q-drawer
        v-model="drawer"
        show-if-above
        :width="200"
        :breakpoint="500"
        bordered
        content-class="bg-blue-grey-10 text-white"
      >
        <q-scroll-area class="fit">
          <q-list v-for="(menuItem, index) in menuList" :key="index">

            <q-item clickable :active="menuItem.label === currentNav" 
              @click="navigateTo(menuItem.label)" v-ripple
              active-class="text-yellow-3"
            >
              <q-item-section avatar>
                <q-icon :name="menuItem.icon" />
              </q-item-section>
              <q-item-section>
                {{ menuItem.label }}
              </q-item-section>
            </q-item>

            <q-separator v-if="menuItem.separator" />

          </q-list>
        </q-scroll-area>
      </q-drawer>
    </q-layout>
  </div>
</template>

<script>
const menuList = [
  {
    icon: 'ti-dashboard',
    label: 'Dashboard',
    separator: true
  },
  {
    icon: 'ti-server',
    label: 'Databases',
    separator: true
  },
  {
    icon: 'ti-layers-alt',
    label: 'Collections',
    separator: false
  },
  {
    icon: 'ti-link',
    label: 'Relations',
    separator: false
  },
  {
    icon: 'ti-settings',
    label: 'Settings',
    separator: false
  }
]
module.exports = {
  data() {
      return {
        drawer: false,
        menuList
      }
  },
  created () {
    this.$actions.fetchConfig()
  },
  mounted: function () {
    // this.$router.push('/home/dashboard');
  },
  computed: {
    currentNav() {
      return this.$nav.current
    }
  },
  methods: {
    navigateTo(menu) {
      this.$router.push({name: menu}).catch(()=>{})
    },
    goBack() {
      window.history.length > 1 ? this.$router.go(-1) : this.$router.push('/')
    }
  }
}
</script>
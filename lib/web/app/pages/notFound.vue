<template>
    <q-layout class="column flex-center">
        <q-banner class="bg-grey-2">
            <div class="text-h1 text-orange">
                <q-icon name="ti-pulse"></q-icon> Page Not Found
            </div>
        </q-banner>
        <q-banner class="bg-grey-2">
            <div class="text-overline text-grey-8">
                {{currentRoute}}
            </div>
        </q-banner>
    </q-layout>
</template>

<script>
module.exports = {
    data () {
        return {
            currentRoute: this.$route.path
        }
    },
    mounted: function () {
    this.$nav.current = 'NotFound'
  },
}
</script>
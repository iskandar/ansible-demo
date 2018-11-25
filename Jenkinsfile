node('linux') {
    // Mark the code checkout 'stage'....
    stage 'Checkout'

    // Get some code from a GitHub repository
    scm checkout
    
    // Mark the code build 'stage'....
    stage 'Build'
    // Run the maven build
    dir('app') {
        sh "mvn package"
        stage 'Archive'
        archive 'ear/target/*ear'
    }
}

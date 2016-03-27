node('linux') {
    // Mark the code checkout 'stage'....
    stage 'Checkout'

    // Get some code from a GitHub repository
    git url: 'https://github.com/iskandar/ansible-demo.git'

    // Get our tools        
    def mvnHome = tool 'mvn3'
    def javaHome = tool 'java8'
    
    // Mark the code build 'stage'....
    stage 'Build'
    // Run the maven build
    dir('app') {
        withEnv(['JAVA_HOME=' + javaHome]) {
            sh "${mvnHome}/bin/mvn package"
        }
        stage 'Archive'
        archive 'ear/target/*ear'
    }
}

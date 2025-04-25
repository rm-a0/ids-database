using DotNetEnv;

namespace App.Helpers
{
    public static class EnvironmentHelper
    {
        public static void LoadEnvironmentVariables()
        {
            Env.Load();
        }
    }
}
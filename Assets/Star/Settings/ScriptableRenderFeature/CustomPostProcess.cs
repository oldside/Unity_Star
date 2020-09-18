using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace UnityEngine.Experimental.Rendering.Universal
{
    public class CustomPostProcess : ScriptableRendererFeature
    {
        [System.Serializable]
        public class Settings
        {
            public Material Material;
            public RenderPassEvent RenderPassEvent;
            public int GaussianBlurIntensity;
            public int Quality = 8;

        }

        public Settings settings = new Settings();

        CustomPostProcessPass m_ScriptablePass;

        public override void Create()
        {
            m_ScriptablePass = new CustomPostProcessPass();

            m_ScriptablePass.renderPassEvent = settings.RenderPassEvent;

            settings.GaussianBlurIntensity = Mathf.Max(0, settings.GaussianBlurIntensity);
            settings.Quality = Mathf.Clamp(settings.Quality, 0, 8);
        }


        public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
        {

            m_ScriptablePass.Setup(settings.Material, renderer.cameraColorTarget,settings.GaussianBlurIntensity, settings.Quality);
            renderer.EnqueuePass(m_ScriptablePass);
        }
    }


}
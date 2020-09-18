using System;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace UnityEngine.Experimental.Rendering.Universal
{ 
    internal class CustomPostProcessPass : ScriptableRenderPass
    {
        private RenderTargetIdentifier Source;
        private Material Material;
        private RenderTargetHandle TmpRT01;
        private RenderTargetHandle TmpRT02;
        
        private int GaussianBlurIntensity;

        private int Quality;

        public void Setup (Material Material,RenderTargetIdentifier Source,int GaussianBlurIntensity, int Quality)
        {
            this.Source = Source;
            this.Material = Material;
            this.GaussianBlurIntensity = GaussianBlurIntensity;
            this.Quality = Quality;
        }

        public override void Configure(CommandBuffer cmd, RenderTextureDescriptor cameraTextureDescriptor)
        {
            TmpRT01.Init("tmpRT01");
            TmpRT02.Init("tmpRT02");
        }
    
    
        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            CommandBuffer Cmd = CommandBufferPool.Get();
            RenderTextureDescriptor TmpRTDescriptor = renderingData.cameraData.cameraTargetDescriptor;
            TmpRTDescriptor.depthBufferBits = 0;

            //控制采样贴图大小，方便性能优化
            TmpRTDescriptor.height /= (int)Mathf.Pow(2, 8 - Quality);
            TmpRTDescriptor.width /= (int)Mathf.Pow(2, 8 - Quality);

            Cmd.GetTemporaryRT(TmpRT01.id, TmpRTDescriptor);
            Cmd.GetTemporaryRT(TmpRT02.id, TmpRTDescriptor);

            //通过tag获取球体
            GameObject StarObject = GameObject.FindGameObjectWithTag("Star");

            //获取球体模型的中心的观察空间位置传递给shader
            if (StarObject == null)
            {
                Material.SetVector("_StarPositionVS", new Vector3(0,0,0));
            }
            else
            {
                Vector3 StarObjectPositionVS = renderingData.cameraData.camera.WorldToViewportPoint(StarObject.transform.position);
                Material.SetVector("_StarPositionVS", StarObjectPositionVS);
            }

            
            Blit(Cmd, Source, TmpRT01.Identifier(), Material, 0);

            //Gaussian Blur
            for (int i = 0; i < GaussianBlurIntensity; i++)
            {
               Blit(Cmd, TmpRT01.Identifier(), TmpRT02.Identifier(), Material, 1);
               Blit(Cmd, TmpRT02.Identifier(), TmpRT01.Identifier(), Material, 2);
            }

            Blit(Cmd, TmpRT01.Identifier(), Source, Material, 3);
            context.ExecuteCommandBuffer(Cmd);
            CommandBufferPool.Release(Cmd);

        }
    
        public override void FrameCleanup(CommandBuffer cmd)
        {
            cmd.ReleaseTemporaryRT(TmpRT01.id);
            cmd.ReleaseTemporaryRT(TmpRT02.id);
        }
    }

}
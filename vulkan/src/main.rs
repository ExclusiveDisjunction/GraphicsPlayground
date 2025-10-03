//! Code to demostrate the compute steps needed for Vulkan

use std::fmt::Display;
use std::process::ExitCode;
use std::sync::Arc;

use vulkano::buffer::{AllocateBufferError, Buffer, BufferCreateInfo, BufferUsage, Subbuffer};
use vulkano::command_buffer::allocator::StandardCommandBufferAllocator;
use vulkano::command_buffer::{AutoCommandBufferBuilder, CommandBufferUsage};
use vulkano::descriptor_set::allocator::StandardDescriptorSetAllocator;
use vulkano::descriptor_set::{DescriptorSet, WriteDescriptorSet};
//use vulkano::command_buffer::allocator::{StandardCommandBufferAllocator, StandardCommandBufferAllocatorCreateInfo};
//use vulkano::command_buffer::{AutoCommandBufferBuilder, CommandBufferUsage, CopyBufferInfo};
use vulkano::device::{QueueFlags, Queue, Device, DeviceCreateInfo, QueueCreateInfo};
use vulkano::memory::allocator::{AllocationCreateInfo, MemoryAllocator, MemoryTypeFilter, StandardMemoryAllocator};
use vulkano::pipeline::compute::ComputePipelineCreateInfo;
use vulkano::pipeline::layout::PipelineDescriptorSetLayoutCreateInfo;
use vulkano::pipeline::{ComputePipeline, Pipeline, PipelineBindPoint, PipelineLayout, PipelineShaderStageCreateInfo};
use vulkano::sync::GpuFuture;
use vulkano::{LoadingError, Validated, VulkanError, VulkanLibrary};
use vulkano::instance::{Instance, InstanceCreateInfo, InstanceCreateFlags};

mod glsl {
    vulkano_shaders::shader! {
        ty: "compute",
        path: "src/compute.glsl",
    }
}

pub struct DeviceResources {
    pub device: Arc<Device>,
    pub queue: Arc<Queue>,
    pub family_index: u32
}
#[derive(Debug)]
pub enum DeviceCreateError {
    Library(LoadingError),
    Instance(Validated<VulkanError>),
    NoDevices,
    DeviceEnum(VulkanError),
    NoQueueFamily,
    DeviceCreate(Validated<VulkanError>),
    NoComputeQueues
}
impl Display for DeviceCreateError {
   fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
       match self {
           Self::Library(e) => write!(f, "Unable to load the library: '{e}'"),
           Self::Instance(e) => write!(f, "Unable to create a device instance: '{e}'"),
           Self::NoDevices => write!(f, "There are no devices present"),
           Self::DeviceEnum(e) => write!(f, "Unable to enumerate devices: '{e}'"),
           Self::NoQueueFamily => write!(f, "There are no compute-enabled queue families"),
           Self::DeviceCreate(e) => write!(f, "Unable to create a device and queue iterator: '{e}'"),
            Self::NoComputeQueues => write!(f, "There are no compute queues to utilize")
       }
   } 
}

fn create_device() -> Result<DeviceResources, DeviceCreateError> {
    // Everything starts with the  library, and then a device.
    // If creating the library fails, there is no supporting vulkan library on device.
    let library = VulkanLibrary::new()
          .map_err(DeviceCreateError::Library)?;

    let instance_create_flags = InstanceCreateInfo {
        flags: InstanceCreateFlags::ENUMERATE_PORTABILITY,
        ..Default::default()
    };
    let instance = Instance::new(library, instance_create_flags) 
               .map_err(DeviceCreateError::Instance)?;

    println!("Instance created.");
    println!("Attempting to select the first device.");
    let physical_device = match instance.enumerate_physical_devices() {
        Ok(mut iterator) => match iterator.next() {
            Some(v) => v,
            None => { 
                return Err( DeviceCreateError::NoDevices );
            }
        },
        Err(e) => {
            return Err( DeviceCreateError::DeviceEnum(e) );
        }
    };

    println!("Device selected.");

    // Now we have to do a queue.
    // Queues are multiple threads on the graphics card.
    // Queues are grouped into queue families.
    // Since we are doing compute, we must find the first queue that supports compute operations. 
    
    let queue_family_index = physical_device
        .queue_family_properties()
        .iter()
        .enumerate()
        .position(|(_, properties)| properties.queue_flags.contains(QueueFlags::COMPUTE));

    let queue_family_index = match queue_family_index {
        Some(v) => v as u32,
        None => {
            return Err( DeviceCreateError::NoQueueFamily );
        }
    };
    let dev_create_info = DeviceCreateInfo {
        queue_create_infos: vec![
            QueueCreateInfo {
                queue_family_index,
                ..Default::default()
            }
        ],
        ..Default::default()
    };

    // Now that we have our queue information, we can construct a device and queue iterator.
    // The family returns a series of queues, we only need the first one.
    let (device, mut queues) = Device::new(physical_device, dev_create_info)
        .map_err(DeviceCreateError::DeviceCreate)?;

    let queue = match queues.next() {
        Some(q) => q,
        None => {
            return Err( DeviceCreateError::NoComputeQueues );
        }
    };

    println!("Device and queue have been selected.");

    Ok(
        DeviceResources {
            device,
            queue,
            family_index: queue_family_index
        }
    )
}

pub struct GpuBuffers {
    pub buff_a: Subbuffer<[f32]>,
    pub buff_b: Subbuffer<[f32]>,
    pub result: Subbuffer<[f32]>
}
impl GpuBuffers {
    pub fn create<M: MemoryAllocator>(alloc: &Arc<M>, i_a: Vec<f32>, i_b: Vec<f32>) -> Result<Self, Validated<AllocateBufferError>> {
        assert_eq!(i_a.len(), i_b.len());
        let input_create_info = BufferCreateInfo {
            usage: BufferUsage::STORAGE_BUFFER,
            ..Default::default()
        };
        let input_alloc_info = AllocationCreateInfo {
            memory_type_filter: MemoryTypeFilter::PREFER_DEVICE | 
                MemoryTypeFilter::HOST_SEQUENTIAL_WRITE,
            ..Default::default()
        };

        let len = i_a.len();
        
        let buff_a = Buffer::from_iter(
            alloc.clone(),
            input_create_info.clone(),
            input_alloc_info.clone(),
            i_a.into_iter()
        )?;
        let buff_b = Buffer::from_iter(
            alloc.clone(),
            input_create_info,
            input_alloc_info,
            i_b.into_iter()
        )?;

        let result = Buffer::new_slice(
            alloc.clone(), 
            BufferCreateInfo {
                 usage: BufferUsage::STORAGE_BUFFER,
                ..Default::default()
            }, 
            AllocationCreateInfo {
                memory_type_filter: MemoryTypeFilter::PREFER_DEVICE | 
                MemoryTypeFilter::HOST_RANDOM_ACCESS,
                ..Default::default()
            },
            len as u64
        )?;

        debug_assert_eq!(result.len(), buff_a.len());

        Ok(
            Self {
                buff_a,
                buff_b,
                result
            }
        )
    }
}

fn main() -> Result<(), ExitCode> {
    let device = match create_device() {
        Ok(v) => v,
        Err(e) => {
            eprintln!("Unable to create device: '{e}'");
            return Err( ExitCode::FAILURE );
        }
    };

    let memory_alloc = Arc::new(
        StandardMemoryAllocator::new_default(device.device.clone())
    );

    println!("Obtaining buffers.");
    let buff = match GpuBuffers::create(&memory_alloc, vec![1.0, 2.0, 3.0, 4.0], vec![4.0, 3.0, 2.0, 1.0]) {
        Ok(v) => v,
        Err(e) => {
            eprintln!("Unable to obtain the buffers: '{e}'");
            return Err( ExitCode::FAILURE );
        }
    };
    println!("Buffers obtained.");

    /*
    println!("Obtaining the command buffer allocator.");
    let _command_buff_alloc = Arc::new(StandardCommandBufferAllocator::new(
        device.device.clone(),
        StandardCommandBufferAllocatorCreateInfo::default()
    ));

   
    let mut builder = match AutoCommandBufferBuilder::primary(
        command_buff_alloc.clone(),
        device.family_index,
        CommandBufferUsage::OneTimeSubmit
    ) {
        Ok(v) => v,
        Err(e) => {
            eprintln!("Unable to create a command buffer builder: '{e}'");
            return Err( ExitCode::FAILURE );
        }
    };
     */
        
    let shader = match glsl::load(device.device.clone()) {
        Ok(v) => v,
        Err(e) => {
            eprintln!("Unable to obtain the shader: '{e}'");
            return Err( ExitCode::FAILURE );
        }
    };

    let entry = match shader.entry_point("main") {
        Some(v) => v,
        None => {
            eprintln!("No main is provided in the shader.");
            return Err( ExitCode::FAILURE );
        }
    };
    let stage = PipelineShaderStageCreateInfo::new(entry);
    let layout = match PipelineLayout::new(
        device.device.clone(),
        PipelineDescriptorSetLayoutCreateInfo::from_stages([&stage])
            .into_pipeline_layout_create_info(device.device.clone())
            .unwrap(),
    ) {
        Ok(v) => v,
        Err(e) => {
            eprintln!("Unable to create a pipeline layout '{e}'");
            return Err( ExitCode::FAILURE );
        }
    };

    let compute_pipeline = match ComputePipeline::new(
        device.device.clone(),
        None,
        ComputePipelineCreateInfo::stage_layout(stage, layout)
    ) {
        Ok(v) => v,
        Err(e) => {
            eprintln!("Unable to create the compute pipeline '{e}'");
            return Err( ExitCode::FAILURE );
        }
    };

    println!("Compute pipeline created.");
    println!("Creating descriptor sets and binding buffers.");

    let descriptor_set_alloc = Arc::new(
        StandardDescriptorSetAllocator::new(
            device.device.clone(), 
            Default::default()
        )
    );
    let pipeline_layout = compute_pipeline.layout();
    let descriptor_set_layouts = pipeline_layout.set_layouts();

    let descriptor_set_layout = descriptor_set_layouts
        .get(0)
        .expect("Expects at least one descriptor set.");
    let descriptor_set = DescriptorSet::new(
        descriptor_set_alloc.clone(),
        descriptor_set_layout.clone(),
        [
            WriteDescriptorSet::buffer(0, buff.buff_a),
            WriteDescriptorSet::buffer(1, buff.buff_b),
            WriteDescriptorSet::buffer(2, buff.result.clone())
        ],
        []
    ).expect("Unable to create a persistent descriptor set.");

    println!("Persistent descriptor set created.");

    let command_buffer_alloc = Arc::new(
        StandardCommandBufferAllocator::new(
            device.device.clone(),
            Default::default()
        )
    );
    let mut command_buffer_builder = match AutoCommandBufferBuilder::primary(
        command_buffer_alloc.clone(),
        device.family_index,
        CommandBufferUsage::OneTimeSubmit
    ) {
        Ok(v) => v,
        Err(e) => {
            eprintln!("Unable to create the command buffer builder '{e}'");
            return Err( ExitCode::FAILURE );
        }
    };

    let work_groups = [1024, 1, 1];

    unsafe {
    command_buffer_builder
        .bind_pipeline_compute(compute_pipeline.clone())
        .unwrap()
        .bind_descriptor_sets(
            PipelineBindPoint::Compute,
            compute_pipeline.layout().clone(),
            0,
            descriptor_set
        )
        .unwrap()
        .dispatch(work_groups)
        .unwrap();
    }

    let command_buffer = match command_buffer_builder.build() {
        Ok(v) => v,
        Err(e) => {
            eprintln!("Unable to create the command buffer '{e}'");
            return Err( ExitCode::FAILURE );
        }
    };

    println!("Computation beginning.");

    let future = vulkano::sync::now(device.device.clone())
        .then_execute(device.queue.clone(), command_buffer)
        .unwrap()
        .then_signal_fence_and_flush()
        .unwrap();
    future.wait(None).unwrap();

    println!("Computation complete.");
    println!("Results:");
    let content = buff.result.read().unwrap();
    for item in content.iter() {
        println!("{item}");
    }

    Ok( () )
}
